#!/usr/bin/env python3
"""JSON-lines supervisor. One subprocess per enabled mode; no shell execution."""
import asyncio
import json
import os
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
RESERVED = {"apps", "tray", "devices", "wifi", "bluetooth"}
LIMIT = 1024 * 1024


def discover(config_path=None, user_path=None):
    config_path = config_path or Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "boron/plugins.json"
    user_path = user_path or Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share")) / "boron/plugins"
    # The checked-in config explicitly enables the bundled GitHub plugin.
    config_path = Path(config_path)
    settings = json.loads((config_path if config_path.exists() else ROOT / "plugins.json").read_text())
    enabled = settings.get("enabled", [])
    modes, errors, seen = [], [], set(RESERVED)
    manifests = sorted((ROOT / "plugins").glob("*/manifest.json")) + sorted(Path(user_path).glob("*/manifest.json"))
    for path in manifests:
        try:
            data = json.loads(path.read_text())
            mode_id = data["id"]
            if mode_id not in enabled:
                continue
            if data.get("protocolVersion") != 1 or not isinstance(mode_id, str) or not mode_id:
                raise ValueError("unsupported protocol or invalid id")
            aliases = data.get("aliases", [])
            names = [mode_id] + aliases
            if any(not isinstance(n, str) or not n or n in seen for n in names) or len(set(names)) != len(names):
                raise ValueError("duplicate mode ID or alias")
            argv = data["command"]
            if not isinstance(argv, list) or not argv or any(not isinstance(a, str) or not a for a in argv):
                raise ValueError("command must be a nonempty string array")
            if not isinstance(data.get("label"), str):
                raise ValueError("label is required")
            seen.update(names)
            data["cwd"] = str(path.parent)
            data["config"] = settings.get("config", {}).get(mode_id, {})
            modes.append(data)
        except (ValueError, KeyError, TypeError) as exc:
            errors.append(f"{path.parent.name}: {exc}")
    return modes, errors


def validate(response):
    if not isinstance(response, dict) or "id" not in response:
        raise ValueError("response must have an id")
    if "error" in response:
        if not isinstance(response["error"], str):
            raise ValueError("error must be text")
        return response
    result = response.get("result")
    if not isinstance(result, dict):
        raise ValueError("result must be an object")
    if "items" in result:
        items = result["items"]
        if not isinstance(items, list) or len(items) > 200:
            raise ValueError("at most 200 results allowed")
        ids = set()
        for item in items:
            if not isinstance(item, dict) or not isinstance(item.get("id"), str) or not isinstance(item.get("title"), str) or item["id"] in ids:
                raise ValueError("results need unique string IDs and titles")
            ids.add(item["id"])
            for action in item.get("actions", []):
                if not isinstance(action.get("id"), str) or not isinstance(action.get("title"), str):
                    raise ValueError("invalid action")
    prompt = result.get("prompt")
    if prompt is not None:
        if not isinstance(prompt, dict) or not isinstance(prompt.get("title"), str) or not isinstance(prompt.get("fields", []), list):
            raise ValueError("invalid prompt")
        for field in prompt.get("fields", []):
            if not isinstance(field.get("id"), str) or field.get("type") not in ("text", "password", "select"):
                raise ValueError("invalid prompt field")
            if field["type"] == "select" and (not isinstance(field.get("options"), list) or not field["options"]):
                raise ValueError("select requires options")
    return response


class Worker:
    def __init__(self, spec, emit):
        self.spec, self.emit = spec, emit
        self.process = None
        self.pending = {}
        self.sequence = 0
        self.lock = asyncio.Lock()
        self.reader_task = None
        self.initialized = False

    async def start(self):
        async with self.lock:
            if self.process and self.process.returncode is None and self.initialized:
                return
            if self.process:
                await self.stop()
            self.process = await asyncio.create_subprocess_exec(*self.spec["command"], cwd=self.spec["cwd"],
                stdin=asyncio.subprocess.PIPE, stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.DEVNULL, limit=LIMIT)
            self.reader_task = asyncio.create_task(self.read())
            try:
                await self.call("initialize", {"protocolVersion": 1, "config": self.spec.get("config", {})}, timeout=5)
                self.initialized = True
            except BaseException:
                await self.stop()
                raise

    async def read(self):
        reason = "Plugin stopped. Retry to restart."
        try:
            while line := await self.process.stdout.readline():
                response = validate(json.loads(line))
                future = self.pending.get(response["id"])
                if future and not future.done():
                    future.set_result(response)
        except (ValueError, KeyError, TypeError) as exc:
            reason = "Invalid plugin response. Retry to restart."
            if self.process.returncode is None:
                self.process.kill()
        finally:
            for future in list(self.pending.values()):
                if not future.done():
                    future.set_exception(RuntimeError(reason))

    async def call(self, method, params, timeout=15):
        self.sequence += 1
        request_id = self.sequence
        future = asyncio.get_running_loop().create_future()
        self.pending[request_id] = future
        try:
            self.process.stdin.write((json.dumps({"id": request_id, "method": method, "params": params}) + "\n").encode())
            await self.process.stdin.drain()
            response = await asyncio.wait_for(future, timeout)
            if "error" in response:
                raise RuntimeError(response["error"])
            return response["result"]
        except asyncio.CancelledError:
            if self.process.returncode is None:
                self.process.stdin.write((json.dumps({"id": None, "method": "cancel", "params": {"id": request_id}}) + "\n").encode())
            raise
        finally:
            self.pending.pop(request_id, None)

    async def stop(self):
        self.initialized = False
        if self.process and self.process.returncode is None:
            try:
                self.process.stdin.write(b'{"id":null,"method":"shutdown","params":{}}\n')
                await self.process.stdin.drain()
                await asyncio.wait_for(self.process.wait(), 0.5)
            except (asyncio.TimeoutError, BrokenPipeError, ConnectionError):
                if self.process.returncode is None:
                    self.process.kill()
                await self.process.wait()
        if self.reader_task:
            await asyncio.gather(self.reader_task, return_exceptions=True)
        self.process = None


class Host:
    def __init__(self, specs):
        self.workers = {s["id"]: Worker(s, self.emit) for s in specs}
        self.tasks = {}
        self.mutating = set()

    def emit(self, data):
        print(json.dumps(data), flush=True)

    async def request(self, message):
        mode, method, request_id = message.get("mode"), message.get("method"), message.get("id")
        worker = self.workers.get(mode)
        if not worker:
            self.emit({"id": request_id, "mode": mode, "error": "Unknown plugin"})
            return
        if method == "cancel":
            task = self.tasks.get(mode)
            if task and mode not in self.mutating:
                task.cancel()
            return
        if mode in self.mutating:
            self.emit({"id": request_id, "mode": mode, "error": "An action is still running."})
            return
        previous = self.tasks.get(mode)
        if previous:
            previous.cancel()
        if method == "activate" and message.get("params", {}).get("values", {}).get("confirmed", False):
            self.mutating.add(mode)
        task = asyncio.create_task(self.perform(worker, message, previous))
        self.tasks[mode] = task

    async def perform(self, worker, message, previous=None):
        mode, method, request_id = message["mode"], message["method"], message["id"]
        mutation = method == "activate" and message.get("params", {}).get("values", {}).get("confirmed", False)
        if mutation:
            self.mutating.add(mode)
        try:
            if previous:
                await asyncio.gather(previous, return_exceptions=True)
            if method == "retry":
                await worker.stop()
                method = "query"
            await worker.start()
            result = await worker.call(method, message.get("params", {}), timeout=45 if mutation else 15)
            self.emit({"id": request_id, "mode": mode, "result": result})
        except asyncio.CancelledError:
            pass
        except asyncio.TimeoutError:
            await worker.stop()
            self.emit({"id": request_id, "mode": mode, "error": "Action outcome uncertain. Refresh service state before trying again." if mutation else "Plugin timed out. Retry to restart.", "uncertain": mutation})
        except Exception as exc:
            self.emit({"id": request_id, "mode": mode, "error": ("Action outcome uncertain. Refresh service state. " if mutation else "") + str(exc)})
        finally:
            if self.tasks.get(mode) is asyncio.current_task():
                self.mutating.discard(mode)


async def main():
    try:
        specs, errors = discover()
    except Exception:
        specs, errors = [], ["Cannot read plugins.json. Check the configuration format."]
    host = Host(specs)
    host.emit({"type": "registry", "modes": [{k: s[k] for k in ("id", "label", "aliases", "icon") if k in s} for s in specs], "errors": errors})
    reader = asyncio.StreamReader(limit=LIMIT)
    await asyncio.get_running_loop().connect_read_pipe(lambda: asyncio.StreamReaderProtocol(reader), sys.stdin)
    try:
        while line := await reader.readline():
            try:
                await host.request(json.loads(line))
            except (ValueError, KeyError, TypeError):
                host.emit({"error": "Invalid host request"})
    finally:
        for task in host.tasks.values():
            task.cancel()
        await asyncio.gather(*host.tasks.values(), return_exceptions=True)
        await asyncio.gather(*(w.stop() for w in host.workers.values()))


if __name__ == "__main__":
    asyncio.run(main())
