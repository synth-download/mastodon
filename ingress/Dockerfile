# syntax=docker/dockerfile:1.12

# Please see https://docs.docker.com/engine/reference/builder for information about
# the extended buildx capabilities used in this file.
# Make sure multiarch TARGETPLATFORM is available for interpolation
# See: https://docs.docker.com/build/building/multi-platform/
ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG BASE_REGISTRY="docker.io"

# Python version to use in base image, change with [--build-arg PYTHON_VERSION="3.12"]
ARG PYTHON_VERSION="3.12"
# Debian image to use for base image, change with [--build-arg DEBIAN_VERSION="bookworm"]
ARG DEBIAN_VERSION="bookworm"
FROM ${BASE_REGISTRY}/python:${PYTHON_VERSION}-slim-${DEBIAN_VERSION} AS ingress
COPY --from=ghcr.io/astral-sh/uv:0.7.12 /uv /uvx /bin/

# Resulting version string is vX.X.X-MASTODON_VERSION_PRERELEASE+MASTODON_VERSION_METADATA
# Example: v4.3.0-nightly.2023.11.09+pr-123456
# Overwrite existence of 'alpha.X' in version.rb [--build-arg MASTODON_VERSION_PRERELEASE="nightly.2023.11.09"]
ARG MASTODON_VERSION_PRERELEASE=""
# Append build metadata or fork information to version.rb [--build-arg MASTODON_VERSION_METADATA="pr-123456"]
ARG MASTODON_VERSION_METADATA=""

# Timezone used by the Docker container and runtime, change with [--build-arg TZ=Europe/Berlin]
ARG TZ="Etc/UTC"
# Linux UID (user id) for the mastodon user, change with [--build-arg UID=1234]
ARG UID="991"
# Linux GID (group id) for the mastodon user, change with [--build-arg GID=1234]
ARG GID="991"

# Apply Mastodon build options based on options above
ENV \
# Apply Mastodon version information
  MASTODON_VERSION_PRERELEASE="${MASTODON_VERSION_PRERELEASE}" \
  MASTODON_VERSION_METADATA="${MASTODON_VERSION_METADATA}" \
# Apply timezone
  TZ=${TZ}

ENV \
# Add Ruby and Mastodon installation to the PATH
  DEBIAN_FRONTEND="noninteractive"

# Set default shell used for running commands
SHELL ["/bin/bash", "-o", "pipefail", "-o", "errexit", "-c"]

ARG TARGETPLATFORM

RUN echo "Target platform is ${TARGETPLATFORM}"

RUN \
# Remove automatic apt cache Docker cleanup scripts
  rm -f /etc/apt/apt.conf.d/docker-clean; \
# Sets timezone
  echo "${TZ}" > /etc/localtime; \
# Creates mastodon user/group and sets home directory
  groupadd -g "${GID}" mastodon; \
  useradd -l -u "${UID}" -g "${GID}" -m -d /opt/mastodon mastodon; \
# Creates symlink for /mastodon folder
  ln -s /opt/mastodon /mastodon;

# hadolint ignore=DL3008,DL3005
RUN \
# Mount Apt cache and lib directories from Docker buildx caches
--mount=type=cache,id=apt-cache-${TARGETPLATFORM},target=/var/cache/apt,sharing=locked \
--mount=type=cache,id=apt-lib-${TARGETPLATFORM},target=/var/lib/apt,sharing=locked \
# Upgrade to check for security updates to Debian image
  apt-get update; \
  apt-get dist-upgrade -yq; \
  apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    tzdata \
    wget \
  ;

# Enable bytecode compilation
ENV UV_COMPILE_BYTECODE=1

# Copy from the cache instead of linking since it's a mounted volume
ENV UV_LINK_MODE=copy

# Set /opt/mastodon as working directory
WORKDIR /opt/mastodon/ingress

COPY ./ingress /opt/mastodon/ingress
RUN --mount=type=cache,id=uv-cache-${TARGETPLATFORM},target=/var/cache/uv,sharing=locked \
    uv sync --locked --no-dev

ENV PATH="/opt/mastodon/ingress/.venv/bin:$PATH"

# Set the running user for resulting container
USER mastodon
# Run ingress when started
CMD ["uv", "run", "main.py"]