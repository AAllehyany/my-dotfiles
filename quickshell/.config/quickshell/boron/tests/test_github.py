import importlib.util
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("github_plugin", ROOT / "plugins/github/plugin.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class GitHubTests(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.log = Path(self.temp.name) / "calls.jsonl"
        self.environment = patch.dict(os.environ, {"PATH": str(ROOT / "tests/fixtures") + os.pathsep + os.environ["PATH"], "BORON_GH_LOG": str(self.log), "BORON_GH_SCENARIO": "success"})
        self.environment.start()
        self.plugin = module.GitHub()
        self.item = {"repo": "owner/repo", "number": 12, "pull_request": {}}

    async def asyncTearDown(self):
        self.environment.stop()
        self.temp.cleanup()

    async def prepare(self):
        prompt = (await self.plugin.prepare_merge(self.item))["prompt"]
        return {"confirmed": True, "method": "squash", **prompt["context"]}

    async def test_search_and_open(self):
        result = await self.plugin.query({"query": "repo:owner/repo fix", "filter": "pulls"})
        self.assertEqual(len(result["items"]), 1)
        item = result["items"][0]
        opened = await self.plugin.handle("activate", {"item": item["id"], "action": "open"})
        self.assertEqual(opened["openUrl"], "https://github.com/owner/repo/pull/12")

    async def test_merge_pins_sha_and_preserves_branch(self):
        values = await self.prepare()
        result = await self.plugin.confirm_merge(values)
        self.assertIn("merged", result["message"])
        calls = [json.loads(line) for line in self.log.read_text().splitlines()]
        merge = next(c for c in calls if c[:2] == ["pr", "merge"])
        self.assertIn("--match-head-commit", merge)
        self.assertIn("abc123", merge)
        self.assertNotIn("--admin", merge)
        self.assertNotIn("--delete-branch", merge)
        with self.assertRaisesRegex(RuntimeError, "expired"):
            await self.plugin.confirm_merge(values)

    async def test_changed_head_never_merges(self):
        values = await self.prepare()
        os.environ["BORON_GH_SCENARIO"] = "changed"
        with self.assertRaisesRegex(RuntimeError, "changed"):
            await self.plugin.confirm_merge(values)
        self.assertNotIn('"merge", "12"', self.log.read_text())

    async def test_method_and_confirmation_required(self):
        values = await self.prepare()
        with self.assertRaisesRegex(RuntimeError, "not allowed"):
            await self.plugin.confirm_merge(dict(values, method="rebase"))
        values = await self.prepare()
        with self.assertRaisesRegex(RuntimeError, "confirmation"):
            await self.plugin.confirm_merge(dict(values, confirmed=False))

    async def test_queue_scheduled_and_uncertain(self):
        for scenario, text in (("queued", "queued"), ("scheduled", "scheduled"), ("unknown", "uncertain")):
            os.environ["BORON_GH_SCENARIO"] = scenario
            result = await self.plugin.confirm_merge(await self.prepare())
            self.assertIn(text, result["message"])

    async def test_rejected_merge(self):
        values = await self.prepare()
        os.environ["BORON_GH_SCENARIO"] = "reject"
        with self.assertRaisesRegex(RuntimeError, "not confirmed"):
            await self.plugin.confirm_merge(values)

    async def test_auth_rate_and_permissions(self):
        for scenario, text in (("auth", "Authentication"), ("rate", "rate limit")):
            os.environ["BORON_GH_SCENARIO"] = scenario
            with self.assertRaisesRegex(RuntimeError, text):
                await self.plugin.query({"query": "test"})
        os.environ["BORON_GH_SCENARIO"] = "denied"
        with self.assertRaisesRegex(RuntimeError, "cannot merge"):
            await self.prepare()


if __name__ == "__main__":
    unittest.main()
