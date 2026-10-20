#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="${IMAGE_NAME:-bluebox-loader:latest}"
if [[ $# -gt 0 ]]; then
  PROFILE_FILE_INPUT="$1"
  shift
else
  PROFILE_FILE_INPUT="$SCRIPT_DIR/profiles/ec2-order-service-sustained-profile.json"
fi

if [[ "$PROFILE_FILE_INPUT" = /* ]]; then
  PROFILE_FILE_HOST="$PROFILE_FILE_INPUT"
else
  PROFILE_FILE_HOST="$SCRIPT_DIR/$PROFILE_FILE_INPUT"
fi

if [[ ! -f "$PROFILE_FILE_HOST" ]]; then
  echo "Profile file not found: $PROFILE_FILE_HOST"
  exit 1
fi

PROFILE_FILE_CONTAINER="/app/profiles/$(basename "$PROFILE_FILE_HOST")"

if [[ -z "${BLUEBOX_DB_PASSWORD:-}" ]]; then
  echo "BLUEBOX_DB_PASSWORD is required. Export it before running this script."
  exit 1
fi

if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
  echo "Docker image not found: $IMAGE_NAME"
  echo "Build it first with: docker build -t $IMAGE_NAME ."
  exit 1
fi

if ! docker network inspect bouncer >/dev/null 2>&1; then
  echo "Creating shared Docker network 'bouncer'..."
  docker network create bouncer
fi

RESOLVED_DB_HOST="${BLUEBOX_DB_HOST:-host.docker.internal}"
if [[ "$RESOLVED_DB_HOST" == "localhost" || "$RESOLVED_DB_HOST" == "127.0.0.1" || "$RESOLVED_DB_HOST" == "::1" ]]; then
  echo "BLUEBOX_DB_HOST=$RESOLVED_DB_HOST resolves to the loader container itself; using host.docker.internal instead."
  RESOLVED_DB_HOST="host.docker.internal"
fi

DOCKER_ARGS=(
  --rm
  --network bouncer
  --add-host=host.docker.internal:host-gateway
  -v "$SCRIPT_DIR/profiles:/app/profiles"
  -e "BLUEBOX_DB_HOST=${RESOLVED_DB_HOST}"
  -e "BLUEBOX_DB_PORT=${BLUEBOX_DB_PORT:-5432}"
  -e "BLUEBOX_DB_NAME=${BLUEBOX_DB_NAME:-bluebox}"
  -e "BLUEBOX_DB_USER=${BLUEBOX_DB_USER:-bb_app}"
  -e "BLUEBOX_DB_PASSWORD=${BLUEBOX_DB_PASSWORD}"
  -e "BLUEBOX_DB_SSLMODE=${BLUEBOX_DB_SSLMODE:-prefer}"
  -e "BLUEBOX_DB_CONNECT_TIMEOUT=${BLUEBOX_DB_CONNECT_TIMEOUT:-10}"
)

CMD_ARGS=(--profile "$PROFILE_FILE_CONTAINER" "$@")

docker run "${DOCKER_ARGS[@]}" "$IMAGE_NAME" "${CMD_ARGS[@]}"
