#!/usr/bin/env bash
set -euo pipefail

# Usage: ./sustained_profile.sh [-v|--verbose]
VERBOSE=0
for arg in "$@"; do
  case $arg in
    -v|--verbose) VERBOSE=1 ;;
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

docker build -t bluebox-loader:latest ./bluebox-loader/

EXTRA_ARGS=()
[[ $VERBOSE -eq 1 ]] && EXTRA_ARGS+=(--verbose)

./bluebox-loader/run-docker.sh profiles/ec2-order-service-sustained-profile.json ${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"}
