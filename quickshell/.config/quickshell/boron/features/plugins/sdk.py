"""Minimal asynchronous Python SDK for Boron protocol v1."""
import asyncio
import json
import sys


async def serve(handler):
    tasks = {}
    async def dispatch(message):
        request_id = message["id"]
        try:
            result = await handler(message["method"], message.get("params", {}))
            print(json.dumps({"id": request_id, "result": result}), flush=True)
        except asyncio.CancelledError:
            pass
        except Exception as exc:
            print(json.dumps({"id": request_id, "error": str(exc)}), flush=True)
        finally:
            tasks.pop(request_id, None)
    reader = asyncio.StreamReader(limit=1024 * 1024)
    await asyncio.get_running_loop().connect_read_pipe(lambda: asyncio.StreamReaderProtocol(reader), sys.stdin)
    try:
        while line := await reader.readline():
            message = json.loads(line)
            if message["method"] == "shutdown":
                break
            if message["method"] == "cancel":
                task = tasks.get(message.get("params", {}).get("id"))
                if task:
                    task.cancel()
            else:
                tasks[message["id"]] = asyncio.create_task(dispatch(message))
    finally:
        for task in list(tasks.values()):
            task.cancel()
        await asyncio.gather(*tasks.values(), return_exceptions=True)
