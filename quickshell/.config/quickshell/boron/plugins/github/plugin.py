#!/usr/bin/env python3
"""GitHub search and explicit PR merge actions, authenticated by gh."""
import asyncio
import json
import os
from pathlib import Path
import secrets
import shutil
import sys
import time

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "features/plugins"))
from sdk import serve


class GitHub:
    def __init__(self):
        self.hostname = "github.com"
        self.items = {}
        self.confirmations = {}

    async def gh(self, *args, decode=True):
        if not shutil.which("gh"):
            raise RuntimeError("Install GitHub CLI (gh), then run gh auth login in your terminal.")
        environment = dict(os.environ, GH_HOST=self.hostname, GH_PROMPT_DISABLED="1", GH_PAGER="cat")
        process = await asyncio.create_subprocess_exec("gh", *args, stdout=asyncio.subprocess.PIPE,
                                                     stderr=asyncio.subprocess.PIPE, env=environment)
        try:
            stdout, stderr = await asyncio.wait_for(process.communicate(), 35)
        except (asyncio.CancelledError, asyncio.TimeoutError):
            if process.returncode is None:
                process.kill()
            await process.wait()
            raise
        if process.returncode:
            text = stderr.decode(errors="replace").strip()
            raise RuntimeError(text or "GitHub request failed. Check gh auth status and network access.")
        return json.loads(stdout) if decode else stdout.decode(errors="replace")

    async def api(self, endpoint, *args):
        return await self.gh("api", "--hostname", self.hostname, endpoint, *args)

    async def snapshot(self, repo, number):
        pr, settings = await asyncio.gather(
            self.gh("pr", "view", str(number), "--repo", self.hostname + "/" + repo,
                    "--json", "number,title,url,state,isDraft,headRefOid,baseRefName,mergeable,mergeStateStatus,reviewDecision,statusCheckRollup,autoMergeRequest"),
            self.api("repos/" + repo))
        methods = [m for m, key in (("squash", "allow_squash_merge"), ("merge", "allow_merge_commit"), ("rebase", "allow_rebase_merge")) if settings.get(key)]
        return pr, methods, settings.get("permissions", {})

    async def query(self, params):
        kind = params.get("filter") or "repositories"
        if kind not in ("repositories", "issues", "pulls"):
            kind = "repositories"
        filters = [{"id": "repositories", "label": "Repositories"}, {"id": "issues", "label": "Issues"}, {"id": "pulls", "label": "Pull requests"}]
        await self.gh("auth", "status", "--hostname", self.hostname, decode=False)
        query = params.get("query", "").strip()
        if not query:
            self.items = {}
            return {"items": [], "filters": filters, "message": "Search GitHub. Qualifiers such as repo:owner/name and author:@me are supported."}
        endpoint = "search/repositories" if kind == "repositories" else "search/issues"
        if kind != "repositories":
            query += " is:pr" if kind == "pulls" else " is:issue"
        data = await self.api(endpoint, "--method", "GET", "-f", "q=" + query, "-f", "per_page=30")
        rows, mapping = [], {}
        for item in data.get("items", []):
            if kind == "repositories":
                key = "repo:" + item["full_name"]
                row = {"id": key, "title": item["full_name"], "subtitle": item.get("description") or "Repository", "actions": [{"id": "open", "title": "Open in browser"}]}
            else:
                repo = item["repository_url"].split("/repos/", 1)[-1]
                key = f"{kind}:{repo}#{item['number']}"
                row = {"id": key, "title": item["title"], "subtitle": f"{repo} #{item['number']} · {item['state']}", "actions": [{"id": "open", "title": "Open in browser"}]}
                item["repo"] = repo
                if "pull_request" in item and item["state"] == "open":
                    row["actions"].append({"id": "merge", "title": "Merge pull request…"})
            mapping[key] = item
            rows.append(row)
        self.items = mapping
        return {"items": rows, "filters": filters}

    async def prepare_merge(self, item):
        repo, number = item["repo"], item["number"]
        pr, methods, permissions = await self.snapshot(repo, number)
        if pr["state"] != "OPEN" or pr["isDraft"]:
            raise RuntimeError("Only open, non-draft pull requests can be merged.")
        if not (permissions.get("push") or permissions.get("maintain") or permissions.get("admin")):
            raise RuntimeError("Your GitHub account cannot merge this pull request.")
        if pr["mergeable"] == "CONFLICTING":
            raise RuntimeError("Resolve merge conflicts before merging.")
        if not methods:
            raise RuntimeError("This repository has no enabled merge methods.")
        token = secrets.token_urlsafe(24)
        self.confirmations[token] = {"repo": repo, "number": number, "sha": pr["headRefOid"], "methods": methods, "expires": time.monotonic() + 300}
        checks = pr.get("statusCheckRollup") or []
        completed = sum(1 for c in checks if c.get("conclusion") in ("SUCCESS", "NEUTRAL", "SKIPPED") or c.get("state") == "SUCCESS")
        description = (f"{repo} #{number} → {pr['baseRefName']}\n{pr['title']}\n"
                       f"Head: {pr['headRefOid'][:12]} · Checks: {completed}/{len(checks)} · Review: {pr.get('reviewDecision') or 'None'}\n"
                       "Repository rules apply. If a merge queue is required, this may queue the PR or schedule it after checks pass. No branch deletion is requested; repository settings may delete it automatically.")
        return {"prompt": {"title": "Confirm pull request merge", "description": description,
                           "submitLabel": "Merge / queue PR", "destructive": True,
                           "action": "confirm-merge", "context": {"token": token},
                           "fields": [{"id": "method", "label": "Merge method", "type": "select", "options": methods, "value": methods[0]}]}}

    async def confirm_merge(self, values):
        confirmation = self.confirmations.pop(values.get("token", ""), None)
        if not confirmation or confirmation["expires"] < time.monotonic():
            raise RuntimeError("Confirmation expired. Open the merge action again.")
        if not values.get("confirmed"):
            raise RuntimeError("Explicit merge confirmation is required.")
        method = values.get("method")
        if method not in confirmation["methods"]:
            raise RuntimeError("Merge method is not allowed.")
        repo, number = confirmation["repo"], confirmation["number"]
        pr, methods, permissions = await self.snapshot(repo, number)
        if pr["headRefOid"] != confirmation["sha"] or pr["state"] != "OPEN" or pr["isDraft"] or method not in methods:
            raise RuntimeError("Pull request changed. Refresh and confirm the merge again.")
        try:
            await self.gh("pr", "merge", str(number), "--repo", self.hostname + "/" + repo,
                          "--" + method, "--match-head-commit", confirmation["sha"], decode=False)
        except Exception as exc:
            # The server may have committed a mutation even when the client did not receive its response.
            state = await self.merge_state(repo, number)
            if state != "open":
                return {"message": f"{repo} #{number}: {state}.", "refresh": True}
            raise RuntimeError("Merge was not confirmed. Refresh the PR before retrying. " + str(exc)) from exc
        state = await self.merge_state(repo, number)
        return {"message": f"{repo} #{number}: {state if state != 'open' else 'request submitted; refresh the PR to verify the outcome'}.", "refresh": True}

    async def merge_state(self, repo, number):
        owner, name = repo.split("/", 1)
        document = "query($owner:String!,$name:String!,$number:Int!){repository(owner:$owner,name:$name){pullRequest(number:$number){state autoMergeRequest{enabledAt} mergeQueueEntry{position}}}}"
        try:
            data = await self.api("graphql", "-f", "query=" + document, "-f", "owner=" + owner, "-f", "name=" + name, "-F", "number=" + str(number))
            pr = data["data"]["repository"]["pullRequest"]
            if pr["state"] == "MERGED":
                return "merged"
            if pr.get("mergeQueueEntry"):
                return "queued for merge"
            if pr.get("autoMergeRequest"):
                return "scheduled to merge after requirements pass"
            return pr["state"].lower()
        except Exception:
            return "outcome uncertain; open the PR in your browser to verify"

    async def handle(self, method, params):
        if method == "initialize":
            self.hostname = params.get("config", {}).get("hostname", "github.com")
            return {}
        if method == "query":
            return await self.query(params)
        if method == "activate":
            if params.get("action") == "confirm-merge":
                return await self.confirm_merge(params.get("values", {}))
            item = self.items.get(params.get("item"))
            if not item:
                raise RuntimeError("Search result expired. Search again.")
            if params.get("action") == "merge" and "pull_request" in item:
                return await self.prepare_merge(item)
            return {"openUrl": item["html_url"]}
        raise RuntimeError("Unsupported request")


if __name__ == "__main__":
    asyncio.run(serve(GitHub().handle))
