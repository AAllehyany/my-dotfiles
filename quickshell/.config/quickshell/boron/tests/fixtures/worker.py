import asyncio
import json
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "features/plugins"))
from sdk import serve

async def handle(method, params):
    query = params.get("query", "")
    if query == "crash":
        sys.exit(7)
    if query == "malformed":
        print("not JSON", flush=True)
        await asyncio.sleep(2)
    if query == "slow":
        await asyncio.sleep(1)
    if query == "hang":
        await asyncio.sleep(60)
    if method == "activate":
        await asyncio.sleep(0.1)
        return {"message": "activated"}
    return {"items": [{"id": query or "ready", "title": query or "Ready"}]}

asyncio.run(serve(handle))
