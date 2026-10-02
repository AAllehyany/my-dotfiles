import asyncio
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "features/plugins"))
from sdk import serve

async def handle(method, params):
    if method == "query":
        return {"items": [{"id": "hello", "title": "Hello " + params.get("query", "world"), "subtitle": "A Python mode with no network dependency", "actions": [{"id": "greet", "title": "Say hello"}]}]}
    if method == "activate":
        return {"message": "Your plugin action ran successfully."}
    return {}

if __name__ == "__main__":
    asyncio.run(serve(handle))
