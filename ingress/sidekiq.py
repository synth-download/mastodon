import redis, json, os
from redis import Sentinel

def get_redis():
    redis_url = os.environ.get("SIDEKIQ_REDIS_URL") or os.environ.get("REDIS_URL")
    if redis_url:
        return redis.Redis.from_url(redis_url, decode_responses=True)

    redis_host = os.environ.get("SIDEKIQ_REDIS_HOST") or os.environ.get("REDIS_HOST") or 'localhost'
    redis_port = os.environ.get("SIDEKIQ_REDIS_PORT") or os.environ.get("REDIS_PORT") or 6379
    redis_user = os.environ.get("SIDEKIQ_REDIS_USER") or os.environ.get("REDIS_USER")
    redis_password = os.environ.get("SIDEKIQ_REDIS_PASSWORD") or os.environ.get("REDIS_PASSWORD")

    if redis_host:
        return redis.Redis(
            host=redis_host,
            port=int(redis_port),
            username=redis_user,
            password=redis_password,
            decode_responses=True
        )

    redis_sentinels = os.environ.get("SIDEKIQ_REDIS_SENTINELS") or os.environ.get("REDIS_SENTINELS")
    redis_sentinel_master = os.environ.get("SIDEKIQ_REDIS_SENTINEL_MASTER") or os.environ.get("REDIS_SENTINEL_MASTER")
    redis_sentinel_port = int(os.environ.get("SIDEKIQ_REDIS_SENTINEL_PORT") or os.environ.get("REDIS_SENTINEL_PORT") or 26379)
    redis_sentinel_username = os.environ.get("SIDEKIQ_REDIS_SENTINEL_USERNAME") or os.environ.get("REDIS_SENTINEL_USERNAME")
    redis_sentinel_password = os.environ.get("SIDEKIQ_REDIS_SENTINEL_PASSWORD") or os.environ.get("REDIS_SENTINEL_PASSWORD")

    if redis_sentinels and redis_sentinel_master:
        sentinels = []
        for pair in redis_sentinels.split(","):
            host, _, port = pair.partition(":")
            sentinels.append((host.strip(), int(port or redis_sentinel_port)))

        sentinel_kwargs = {}
        if redis_sentinel_username or redis_sentinel_password:
            sentinel_kwargs["username"] = redis_sentinel_username
            sentinel_kwargs["password"] = redis_sentinel_password

        sentinel = Sentinel(
            sentinels,
            socket_timeout=2,
            sentinel_kwargs=sentinel_kwargs if sentinel_kwargs else None
        )

        return sentinel.master_for(
            service_name=redis_sentinel_master,
            socket_timeout=2,
            decode_responses=True
        )

    raise RuntimeError("No valid Redis configuration found")

_r = get_redis()

def enqueue_fetch(uri: str):
    payload = {
        'class': 'ActivityPub::FetchStatusWorker',
        'args': [uri],
        'retry': True,
        'queue': 'pull'
    }
    _r.rpush('queue:default', json.dumps(payload, separators=(',',':')))