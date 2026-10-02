import asyncio
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "features/plugins"))
from host import Host, Worker, discover, validate

SPEC = {"id": "fixture", "command": [sys.executable, str(ROOT / "tests/fixtures/worker.py")], "cwd": str(ROOT), "config": {}}


class ProtocolTests(unittest.TestCase):
    def test_validation(self):
        for response in ({}, {"id": 1, "result": []}, {"id": 1, "result": {"items": [{"id": "x"}]}},
                         {"id": 1, "result": {"items": [{"id": "x", "title": "A"}, {"id": "x", "title": "B"}]}}):
            with self.assertRaises(ValueError):
                validate(response)

    def test_discovery_requires_enabled_and_rejects_collision(self):
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            config = base / "plugins.json"
            config.write_text(json.dumps({"enabled": ["custom"]}))
            directory = base / "custom"
            directory.mkdir()
            manifest = {"id": "custom", "label": "Custom", "protocolVersion": 1, "command": ["python3", "plugin.py"], "aliases": ["wifi"]}
            (directory / "manifest.json").write_text(json.dumps(manifest))
            modes, errors = discover(config, base)
            self.assertEqual(modes, [])
            self.assertEqual(len(errors), 1)
            manifest["aliases"] = ["custom-alias"]
            (directory / "manifest.json").write_text(json.dumps(manifest))
            modes, errors = discover(config, base)
            self.assertEqual([m["id"] for m in modes], ["custom"])


class WorkerTests(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self):
        self.worker = Worker(SPEC, lambda _: None)
        await self.worker.start()

    async def asyncTearDown(self):
        await self.worker.stop()

    async def test_roundtrip(self):
        self.assertEqual((await self.worker.call("query", {"query": "hello"}))["items"][0]["id"], "hello")

    async def test_cancel_and_reuse(self):
        task = asyncio.create_task(self.worker.call("query", {"query": "slow"}))
        await asyncio.sleep(0.02)
        task.cancel()
        with self.assertRaises(asyncio.CancelledError):
            await task
        self.assertEqual((await self.worker.call("query", {"query": "new"}))["items"][0]["id"], "new")

    async def test_timeout(self):
        with self.assertRaises(asyncio.TimeoutError):
            await self.worker.call("query", {"query": "hang"}, timeout=0.03)

    async def test_malformed_and_restart(self):
        with self.assertRaisesRegex(RuntimeError, "Invalid plugin"):
            await self.worker.call("query", {"query": "malformed"})
        await self.worker.stop()
        await self.worker.start()
        self.assertIn("items", await self.worker.call("query", {}))

    async def test_crash(self):
        with self.assertRaisesRegex(RuntimeError, "stopped"):
            await self.worker.call("query", {"query": "crash"})


class HostTests(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self):
        self.host = Host([SPEC])
        self.messages = []
        self.host.emit = self.messages.append

    async def asyncTearDown(self):
        await asyncio.gather(*self.host.tasks.values(), return_exceptions=True)
        await asyncio.gather(*(w.stop() for w in self.host.workers.values()))

    async def test_new_query_discards_old(self):
        await self.host.request({"id": 1, "mode": "fixture", "method": "query", "params": {"query": "slow"}})
        await asyncio.sleep(0.05)
        await self.host.request({"id": 2, "mode": "fixture", "method": "query", "params": {"query": "new"}})
        await self.host.tasks["fixture"]
        self.assertEqual([m["id"] for m in self.messages], [2])

    async def test_mutation_is_not_duplicated_or_canceled(self):
        request = {"id": 1, "mode": "fixture", "method": "activate", "params": {"values": {"confirmed": True}}}
        await self.host.request(request)
        await self.host.request(dict(request, id=2))
        await self.host.request({"mode": "fixture", "method": "cancel"})
        await self.host.tasks["fixture"]
        self.assertEqual(sum("result" in m for m in self.messages), 1)
        self.assertTrue(any("still running" in m.get("error", "") for m in self.messages))


if __name__ == "__main__":
    unittest.main()
