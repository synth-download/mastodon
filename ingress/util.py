import sys
import logging

logging.basicConfig(
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    datefmt="%m-%d %H:%M",
    stream=sys.stderr,
    level=logging.INFO,
)
LOGGER = logging.getLogger("Ingress")
