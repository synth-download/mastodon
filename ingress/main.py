import asyncio
import html
import json
import os
import re
import time
from typing import Any, Callable, cast
from urllib.parse import urlparse

import requests
from database import DomainBlocks, ListDefs, psql_pool
from sidekiq import enqueue_fetch
from util import LOGGER

MASTODON_DOMAIN = os.environ.get("WEB_DOMAIN") or os.environ["LOCAL_DOMAIN"]

TIMELINE_API = (
    os.environ.get("INGRESS_TIMELINE_API_URL")
    or "https://fedi.buzz/api/v1/streaming/public"
)
TIMELINE_API_TOKEN = os.environ.get("INGRESS_TIMELINE_API_TOKEN")

TAG_PATTERN: re.Pattern[str] = re.compile(r"<[^>]+>")
DOMAIN_BLOCKS: DomainBlocks = DomainBlocks()
LISTS: ListDefs = ListDefs()


def uri_blocked(uri: str):
    hostname = urlparse(uri).hostname
    if not hostname:
        return False
    blocks: list[str] = []  # TODO
    domain = hostname.lower()
    parts = domain.split(".")
    for i in range(len(parts)):
        candidate_domain = ".".join(parts[i:])
        if candidate_domain in blocks:
            return True
    return False


def handle_status(status: dict[str, Any]) -> None:
    if "uri" not in status:
        return
    if uri_blocked(status["uri"]):
        return

    spoiler: str = status.get("spoiler_text", "")
    content: str = html.unescape(TAG_PATTERN.sub("", status.get("content") or ""))
    tags: str = (
        " ".join("#" + tag["name"] for tag in status["tags"])
        if status.get("tags")
        else ""
    )

    text: str = f"{spoiler}\n{content}\n{tags}".strip()
    if not text:
        return

    if any(kw in text for kw in LISTS.exclude_keywords) or (
        LISTS.exclude_regex and LISTS.exclude_regex.search(text)
    ):
        return

    if not any(kw in text for kw in LISTS.include_keywords) and not (
        LISTS.include_regex and LISTS.include_regex.search(text)
    ):
        return

    LOGGER.info("Pulling... %s", status["uri"])
    enqueue_fetch(status["uri"])


def listen(
    loop: asyncio.AbstractEventLoop,
    stop: asyncio.Event,
    task_queue: asyncio.Queue[Callable[[], None] | None],
) -> None:
    headers: dict[str, str | bytes | None] = {}
    headers["User-Agent"] = f"Mastodon/ingress (+http://{MASTODON_DOMAIN}/)"
    if TIMELINE_API_TOKEN:
        headers["Authorization"] = f"Bearer {TIMELINE_API_TOKEN}"

    LOGGER.info(f"Listening to {TIMELINE_API}...")
    try:
        with requests.get(
            TIMELINE_API, headers=headers, allow_redirects=True, stream=True
        ) as rsp:
            if rsp.status_code != 200:
                rsp.raise_for_status()

            current_event: str | None = None
            for incomplete in rsp.iter_lines():
                if stop.is_set():
                    return

                if not incomplete:
                    continue
                line: str = cast(str, incomplete.decode("utf-8"))
                if line.startswith(":"):
                    continue

                if line.startswith("event:"):
                    current_event = line[6:].strip()
                elif line.startswith("data:") and current_event == "update":
                    data = line[5:].strip()
                    coro = task_queue.put(lambda d=data: handle_status(json.loads(d)))
                    _ = asyncio.run_coroutine_threadsafe(coro, loop)
                    current_event = None
    except Exception:
        LOGGER.exception("Exception in listening task.. Reconnecting in 5 seconds...")
        time.sleep(5)


async def poll(stop: asyncio.Event):
    _ = await asyncio.gather(
        DOMAIN_BLOCKS.poll(stop),
        LISTS.poll(stop),
    )


async def worker(task_queue: asyncio.Queue[Callable[[], None] | None]):
    while True:
        task = await task_queue.get()
        try:
            if task is None:
                break
            if asyncio.iscoroutinefunction(task):
                await task()
            else:
                await asyncio.get_running_loop().run_in_executor(None, task)
        finally:
            task_queue.task_done()


async def run_listener(
    stop: asyncio.Event, task_queue: asyncio.Queue[Callable[[], None] | None]
):
    loop = asyncio.get_running_loop()
    await loop.run_in_executor(None, listen, loop, stop, task_queue)


async def main() -> None:
    task_queue: asyncio.Queue[Callable[[], None] | None] = asyncio.Queue()
    event = asyncio.Event()

    worker_task = asyncio.create_task(worker(task_queue))
    poll_task = asyncio.create_task(poll(event))
    listener_task = asyncio.create_task(run_listener(event, task_queue))

    try:
        await listener_task
    except asyncio.CancelledError:
        LOGGER.info("listener cancelled")
    except KeyboardInterrupt:
        LOGGER.info("Shutting down...")

    event.set()
    await task_queue.put(None)
    await task_queue.join()
    _ = worker_task.cancel()
    _ = poll_task.cancel()
    _ = await asyncio.gather(worker_task, poll_task, return_exceptions=True)
    psql_pool.closeall()


if __name__ == "__main__":
    asyncio.run(main())
