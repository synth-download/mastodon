import logging, requests, json, html, re, os
from database import ListCache
from sidekiq import enqueue_fetch

LOGGER = logging.getLogger("streaming_ingress")
TAG_PATTERN = re.compile(r'<[^>]+>')
TIMELINE_API = os.environ.get('INGRESS_TIMELINE_API_URL') or 'https://fedi.buzz/api/v1/streaming/public'
LISTS = ListCache()

def matches_groups(text: str, groups: list[list[str]]) -> bool:
    if not groups:
        return False

    return any(all(k in text for k in group) for group in groups)

def handle_status(status: dict):
    lists = LISTS.get_lists(status.get('reblog') or False, status.get('media_attachments') or False)
    if not lists:
        return
    
    spoiler = status.get("spoiler_text") or ""
    text = html.unescape(TAG_PATTERN.sub('', status.get('content') or ''))
    texts = [spoiler.lower(), text.lower()]
    
    for _list in lists:
        include_kw: list[list[str]] = _list.get('include_keywords', [])
        exclude_kw: list[list[str]] = _list.get('exclude_keywords', [])
        
        if not any(matches_groups(t, include_kw) for t in texts):
            continue
        if exclude_kw and any(matches_groups(t, exclude_kw) for t in texts):
            continue
        
        enqueue_fetch(status['uri'])
        LOGGER.info("Pulling %s..", status['uri'])
        break

def run_timeline_listener():
    with requests.get(TIMELINE_API, stream=True) as rsp:
        buffer = []
        for line in rsp.iter_lines():
            if line.startswith(b'event:') and line.endswith(b'update'):
                buffer.append(line)
            
            if buffer and line.startswith(b'data:'):
                buffer.pop()
                handle_status(json.loads(line.decode('utf-8')[5:]))
                

if __name__ == "__main__":
    run_timeline_listener()