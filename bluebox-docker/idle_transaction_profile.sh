#!/usr/bin/env bash
set -euo pipefail

# Usage: ./idle_transaction_profile.sh [-v|--verbose] [--build]
# Default behavior is fully local/offline: use an existing local loader image.
VERBOSE=0
DO_BUILD=0
for arg in "$@"; do
  case $arg in
    -v|--verbose) VERBOSE=1 ;;
    --build) DO_BUILD=1 ;;
  esac
done

cd "$(dirname "$0")"

# Load environment from bluebox-loader/.env if it exists
ENV_FILE="./bluebox-loader/.env"
if [[ -f "$ENV_FILE" ]]; then
  echo "Loading config from $ENV_FILE"
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

IMAGE_NAME="${IMAGE_NAME:-bluebox-loader:latest}"

if [[ $DO_BUILD -eq 1 ]]; then
  echo "Rebuilding local loader image: $IMAGE_NAME"
  # --pull=false prevents docker from trying to refresh base layers from the internet.
  docker build --pull=false -t "$IMAGE_NAME" ./bluebox-loader/
else
  if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
    echo "Local image not found: $IMAGE_NAME"
    echo "For an offline run, pre-build it once while online:"
    echo "  docker build -t $IMAGE_NAME ./bluebox-loader/"
    echo "Then re-run this script without --build."
    exit 1
  fi
fi

EXTRA_ARGS=()
[[ $VERBOSE -eq 1 ]] && EXTRA_ARGS+=(--verbose)

IMAGE_NAME="$IMAGE_NAME" ./bluebox-loader/run-docker.sh profiles/idle-in-transaction-profile_new.json ${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"}
