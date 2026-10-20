#!/bin/bash
#
# Build the Bluebox Postgres image from local source, then start it via start.sh
#

set -euo pipefail

cd "$(dirname "$0")"

DEFAULT_PG_VERSION="18"

echo "========================================"
echo "Bluebox Local Build + Start"
echo "========================================"
echo

echo "Available versions: 14, 15, 16, 17, 18, 19-dev"
read -p "Postgres version to build [${DEFAULT_PG_VERSION}]: " PG_VERSION
PG_VERSION=${PG_VERSION:-$DEFAULT_PG_VERSION}

# Validate version
if [[ ! "$PG_VERSION" =~ ^(14|15|16|17|18|19-dev)$ ]]; then
    echo "Error: Unsupported Postgres version. Choose 14, 15, 16, 17, 18, or 19-dev."
    exit 1
fi

IMAGE_NAME="bluebox"
IMAGE_TAG="${IMAGE_NAME}:${PG_VERSION}"

echo
echo "Building ${IMAGE_TAG} from local Dockerfile (this may take a while)..."
docker build --no-cache \
    --build-arg PG_SERVER_VERSION="${PG_VERSION}" \
    -t "${IMAGE_TAG}" \
    -f "$(pwd)/Dockerfile" \
    "$(pwd)"

echo
echo "Build complete: ${IMAGE_TAG}"
echo "Starting container via start.sh using the local image..."
echo

# Feed the version (to match the image we just built) plus a couple of
# blank lines so start.sh's remaining prompts (port, recreate) fall back
# to their defaults instead of blocking on input.
printf '%s\n\n\n' "$PG_VERSION" | BLUEBOX_IMAGE="${IMAGE_NAME}" ./start.sh
