import psycopg2, os, time

DATABASE_URL = os.environ.get('REPLICA_DATABASE_URL') or os.environ.get('DATABASE_URL')
DB_HOST = os.environ.get('REPLICA_DB_HOST') or os.environ.get('DB_HOST')
DB_USER = os.environ.get('REPLICA_DB_USER') or os.environ.get('DB_USER')
DB_NAME = os.environ.get('REPLICA_DB_NAME') or os.environ.get('DB_NAME')
DB_PASS = os.environ.get('REPLICA_DB_PASS') or os.environ.get('DB_PASS')
DB_PORT = os.environ.get('REPLICA_DB_PORT') or os.environ.get('DB_PORT')

if DATABASE_URL:
    conn = psycopg2.connect(DATABASE_URL)
else:
    conn = psycopg2.connect(
        host=DB_HOST or 'localhost',
        user=DB_USER or 'mastodon',
        dbname=DB_NAME or 'mastodon_production',
        password=DB_PASS,
        port=DB_PORT or '5432'
    )
    
class BlockedDomainsCache:
    def __init__(self) -> None:
        self._blocks = set()
        self._last_refresh = 0
    
    def refresh(self):
        now = time.time()
        if now - self._last_refresh < 600:
            return
        
        cur = conn.cursor()
        cur.execute(        """
            SELECT domain_blocks.domain
            FROM domain_blocks
            WHERE domain_blocks.severity = 1;
        """)
        rows = cur.fetchall()
        items = set([row[0] for row in rows])
        cur.close()
        self._blocks = items
        self._last_refresh = now
    
    def get_blocks(self) -> set[str]:
        self.refresh()
        return self._blocks


class ListCache:
    def __init__(self) -> None:
        self._lists = []
        self._last_refresh = 0
    
    def refresh(self):
        now = time.time()
        if now - self._last_refresh < 30:
            return
        
        cur = conn.cursor()
        cur.execute("""
          SELECT lists.id,
                 lists.include_keywords,
                 lists.exclude_keywords,
                 lists.with_media_only,
                 lists.ignore_reblog
          FROM lists
          JOIN accounts ON lists.account_id = accounts.id
          WHERE accounts.domain IS NULL
            AND lists.include_keywords IS NOT NULL
            AND jsonb_array_length(lists.include_keywords) > 0
        """)
        rows = cur.fetchall()
        items = []
        for row in rows:
            id_, include_kw, exclude_kw, with_media_only, ignore_reblog = row
            items.append({
                "id": id_,
                "include_keywords": include_kw,
                "exclude_keywords": exclude_kw,
                "with_media_only": bool(with_media_only),
                "ignore_reblog": bool(ignore_reblog),
            })
        cur.close()
        self._lists = items
        self._last_refresh = now

    def get_lists(self, is_reblog: bool, has_media: bool) -> list[dict]:
        self.refresh()
        out = []
        for list in self._lists:
            if is_reblog and list["ignore_reblog"]:
                continue
            if list["with_media_only"] and not has_media:
                continue
            out.append(list)
        return out