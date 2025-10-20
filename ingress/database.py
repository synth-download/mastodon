import asyncio
import datetime
import json
import os
import re
import threading
from typing import cast
import select

import psycopg2
from util import LOGGER

DATABASE_URL = os.environ.get("REPLICA_DATABASE_URL") or os.environ.get("DATABASE_URL")
DB_HOST = os.environ.get("REPLICA_DB_HOST") or os.environ.get("DB_HOST")
DB_USER = os.environ.get("REPLICA_DB_USER") or os.environ.get("DB_USER")
DB_NAME = os.environ.get("REPLICA_DB_NAME") or os.environ.get("DB_NAME")
DB_PASS = os.environ.get("REPLICA_DB_PASS") or os.environ.get("DB_PASS")
DB_PORT = os.environ.get("REPLICA_DB_PORT") or os.environ.get("DB_PORT")


def get_conn():
    if DATABASE_URL:
        return psycopg2.connect(DATABASE_URL)
    else:
        return psycopg2.connect(
            host=DB_HOST or "localhost",
            user=DB_USER or "mastodon",
            dbname=DB_NAME or "mastodon_production",
            password=DB_PASS,
            port=DB_PORT or "5432",
        )


conn = get_conn()


class DomainBlocks:
    def __init__(self) -> None:
        self._blocks: set[str] = set()
        self._last_poll: float = 0

    def _refresh(self) -> None:
        cur = conn.cursor()
        cur.execute("""
        SELECT domain_blocks.domain
        FROM domain_blocks
        WHERE domain_blocks.severity = 1;
    """)
        items: set[str] = set([row[0] for row in cur.fetchall()])
        cur.close()
        self._blocks = items

    async def poll(self, stop: asyncio.Event):
        while not stop.is_set():
            try:
                self._refresh()
            except Exception:
                LOGGER.exception("Exception in poll task!")
                stop.set()
            await asyncio.sleep(600)


class ListDefs:
    def __init__(self) -> None:
        self.thread: threading.Thread | None = None

        self.include_keywords: set[str] = set()
        self.exclude_keywords: set[str] = set()

        self.include_regex: re.Pattern[str] | None = None
        self.exclude_regex: re.Pattern[str] | None = None

        self.last_updated: datetime.datetime | None = None

    def _refresh(self) -> None:
        cur = conn.cursor()
        cur.execute("""
            SELECT lists.include_keywords,
                    lists.exclude_keywords
            FROM lists
            JOIN accounts ON lists.account_id = accounts.id
            WHERE accounts.domain IS NULL
              AND lists.include_keywords IS NOT NULL
              AND jsonb_array_length(lists.include_keywords) > 0
        """)
        rows = cur.fetchall()
        cur.close()

        include_keywords: set[str] = set()
        exclude_keywords: set[str] = set()

        include_patterns: set[str] = set()
        exclude_patterns: set[str] = set()

        for row in rows:
            include_kw, exclude_kw = row

            for s in cast(list[str], include_kw):
                if not (s.startswith("/") and s.endswith("/")):
                    include_keywords.add(s)
                else:
                    include_patterns.add(s[1:-1])

            for s in cast(list[str], exclude_kw):
                if not (s.startswith("/") and s.endswith("/")):
                    exclude_keywords.add(s)
                else:
                    exclude_patterns.add(s[1:-1])

        self.include_keywords = include_keywords
        self.exclude_keywords = exclude_keywords

        if include_patterns:
            include_pattern = "|".join(include_patterns)
            if not self.include_regex or self.include_regex.pattern != include_pattern:
                self.include_regex = re.compile(include_pattern, re.IGNORECASE)
        else:
            self.include_regex = None

        if exclude_patterns:
            exclude_pattern = "|".join(exclude_patterns)
            if not self.exclude_regex or self.exclude_regex.pattern != exclude_pattern:
                self.exclude_regex = re.compile(exclude_pattern, re.IGNORECASE)
        else:
            self.exclude_regex = None

    def start_listen_thread(self, stop: asyncio.Event, loop: asyncio.AbstractEventLoop):
        listen_conn = get_conn()
        listen_conn.set_isolation_level(psycopg2.extensions.ISOLATION_LEVEL_AUTOCOMMIT)
        cur = listen_conn.cursor()
        cur.execute("LISTEN lists_changed;")
        cur.close()

        def _listen():
            self._refresh()
            while not stop.is_set():
                r, _, _ = select.select([listen_conn], [], [], 5)
                if not r:
                    continue
                try:
                    listen_conn.poll()
                    while listen_conn.notifies:
                        notify = listen_conn.notifies.pop(0)
                        if notify.payload:
                            data = json.loads(notify.payload)
                            if data["table"] == "lists":
                                LOGGER.info("Refreshing lists!")
                                _ = asyncio.run_coroutine_threadsafe(
                                    asyncio.to_thread(self._refresh), loop
                                )
                except Exception:
                    LOGGER.exception("Exception in listen thread")
                    stop.set()
                    break

        self.thread = threading.Thread(target=_listen, daemon=True)
        self.thread.start()

    def stop_listen_thread(self):
        if self.thread:
            self.thread.join(timeout=2)
