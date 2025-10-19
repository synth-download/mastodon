import logging, requests, json, html, sys, re, os
from urllib.parse import urlparse
from database import ListCache, BlockedDomainsCache
from sidekiq import enqueue_fetch

logging.basicConfig(stream=sys.stdout, level=logging.INFO)
LOGGER = logging.getLogger("ingress")
TAG_PATTERN = re.compile(r"<[^>]+>")
TIMELINE_API = (
    os.environ.get("INGRESS_TIMELINE_API_URL")
    or "https://fedi.buzz/api/v1/streaming/public"
)
TIMELINE_API_TOKEN = os.environ.get("INGRESS_TIMELINE_API_TOKEN")
LISTS = ListCache()
BLOCKED_DOMAINS = BlockedDomainsCache()


def matches_filters(
    texts: list[str],
    include_kw: list[str],
    include_rx: list[re.Pattern[str]],
    exclude_kw: list[str],
    exclude_rx: list[re.Pattern[str]],
):
    has_include_match = (
        not include_kw or any(kw in text for kw in include_kw for text in texts)
    ) and (
        not include_rx or any(rx.search(text) for rx in include_rx for text in texts)
    )

    has_exclude_match = any(kw in text for kw in exclude_kw for text in texts) or any(
        rx.search(text) for rx in exclude_rx for text in texts
    )

    return has_include_match and not has_exclude_match


def uri_blocked(uri: str):
    hostname = urlparse(uri).hostname
    if not hostname:
        return False
    blocks = BLOCKED_DOMAINS.get_blocks()

    domain = hostname.lower()
    parts = domain.split(".")
    for i in range(len(parts)):
        candidate_domain = ".".join(parts[i:])
        if candidate_domain in blocks:
            return True
    return False


def handle_status(status: dict):
    uri = status.get("uri")
    if not uri:
        return

    if uri_blocked(uri):
        return

    lists = LISTS.get_lists(
        status.get("reblog") or False, status.get("media_attachments") or False
    )
    if not lists:
        return

    spoiler = status.get("spoiler_text") or ""
    text = html.unescape(TAG_PATTERN.sub("", status.get("content") or ""))
    texts = [spoiler.lower(), text.lower()]

    for _list in lists:
        include: tuple[list[str], list[re.Pattern[str]]] = _list.get(
            "include_keywords", ()
        )
        exclude: tuple[list[str], list[re.Pattern[str]]] = _list.get(
            "exclude_keywords", ()
        )
        include_kw, include_rx = include
        exclude_kw, exclude_rx = exclude

        if not matches_filters(texts, include_kw, include_rx, exclude_kw, exclude_rx):
            continue

        enqueue_fetch(uri)
        LOGGER.info("Pulling %s..", uri)
        break


def run_timeline_listener():
    headers = {}
    if TIMELINE_API_TOKEN:
        headers["Authorization"] = f"Bearer {TIMELINE_API_TOKEN}"

    with requests.get(TIMELINE_API, headers=headers, stream=True) as rsp:
        if rsp.status_code != 200:
            rsp.raise_for_status()

        buffer = []
        for line in rsp.iter_lines():
            if line.startswith(b"event:") and line.endswith(b"update"):
                buffer.append(line)

            if buffer and line.startswith(b"data:"):
                buffer.pop()
                handle_status(json.loads(line.decode("utf-8")[5:]))


if __name__ == "__main__":
    run_timeline_listener()
