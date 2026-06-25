#!/usr/bin/env bash
set -euo pipefail

DEFAULT_LINES=100
LINES="${TAIL_LINES:-$DEFAULT_LINES}"
declare -a PSQL_ARGS=()
MODE="db"
DOCKER_TARGET=""
SERVICE_TARGET=""

if [[ $# -gt 0 && "$1" =~ ^[0-9]+$ ]]; then
  LINES="$1"
  shift
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--lines)
      if [[ $# -lt 2 ]]; then
        echo "Error: --lines requires a value." >&2
        exit 1
      fi
      LINES="$2"
      shift 2
      ;;
    --lines=*)
      LINES="${1#*=}"
      shift
      ;;
    --docker)
      MODE="docker"
      if [[ $# -gt 1 && ! "$2" =~ ^- ]]; then
        DOCKER_TARGET="$2"
        shift 2
      else
        shift
      fi
      ;;
    --docker=*)
      MODE="docker"
      DOCKER_TARGET="${1#*=}"
      shift
      ;;
    --service)
      MODE="service"
      if [[ $# -gt 1 && ! "$2" =~ ^- ]]; then
        SERVICE_TARGET="$2"
        shift 2
      else
        shift
      fi
      ;;
    --service=*)
      MODE="service"
      SERVICE_TARGET="${1#*=}"
      shift
      ;;
    *)
      PSQL_ARGS+=("$1")
      shift
      ;;
  esac
done

if [[ ${#PSQL_ARGS[@]} -eq 0 && -n "${DBA_FLAGS:-}" ]]; then
  # Split simple space-delimited flags from profile, e.g. "-h localhost -d bluebox ..."
  read -r -a PSQL_ARGS <<< "$DBA_FLAGS"
fi

if ! [[ "$LINES" =~ ^[0-9]+$ ]] || (( LINES <= 0 )); then
  echo "Error: line count must be a positive integer." >&2
  echo "Usage: $0 [line_count] [--lines N] [--docker [container]|--service [name]] [psql connection args]" >&2
  exit 1
fi

if [[ "$MODE" == "docker" ]]; then
  TARGET="${DOCKER_TARGET:-${DB_DOCKER_CONTAINER:-postgres}}"

  if ! command -v docker >/dev/null 2>&1; then
    echo "Error: docker CLI not found in PATH." >&2
    exit 1
  fi

  echo "Tailing $LINES lines from Docker container: $TARGET"
  if ! docker logs --tail "$LINES" "$TARGET"; then
    echo "Error: failed to read docker logs for container '$TARGET'." >&2
    echo "Tip: set DB_DOCKER_CONTAINER in your shell profile or pass --docker <container>." >&2
    exit 1
  fi
  exit 0
fi

if [[ "$MODE" == "service" ]]; then
  TARGET="${SERVICE_TARGET:-${DB_DOCKER_SERVICE:-postgres}}"

  if ! command -v docker >/dev/null 2>&1; then
    echo "Error: docker CLI not found in PATH." >&2
    exit 1
  fi

  echo "Tailing $LINES lines from Docker Compose service: $TARGET"
  if ! docker compose logs --no-color --tail "$LINES" "$TARGET"; then
    echo "Error: failed to read docker compose logs for service '$TARGET'." >&2
    echo "Tip: set DB_DOCKER_SERVICE in your shell profile or pass --service <name>." >&2
    exit 1
  fi
  exit 0
fi

PSQL_BIN="${PSQL_BIN:-psql}"

# Preferred: ask PostgreSQL for the current active log file.
CURRENT_LOG_SQL="
SELECT CASE
  WHEN pg_current_logfile() IS NULL OR pg_current_logfile() = '' THEN ''
  WHEN pg_current_logfile() LIKE '/%' THEN pg_current_logfile()
  ELSE current_setting('data_directory') || '/' || pg_current_logfile()
END;
"

if ! CURRENT_LOG_RESULT="$($PSQL_BIN "${PSQL_ARGS[@]}" -X -A -t -q -c "$CURRENT_LOG_SQL" 2>&1)"; then
  echo "Error: failed to query PostgreSQL for log location." >&2
  echo "$CURRENT_LOG_RESULT" >&2
  exit 1
fi

LOG_FILE="$(printf '%s\n' "$CURRENT_LOG_RESULT" | awk 'NF { print; exit }')"

if [[ -z "$LOG_FILE" ]]; then
  LOG_DIR_SQL="
SELECT CASE
  WHEN current_setting('log_directory') LIKE '/%' THEN current_setting('log_directory')
  ELSE current_setting('data_directory') || '/' || current_setting('log_directory')
END;
"

  if ! LOG_DIR_RESULT="$($PSQL_BIN "${PSQL_ARGS[@]}" -X -A -t -q -c "$LOG_DIR_SQL" 2>&1)"; then
    echo "Error: failed to query PostgreSQL log_directory." >&2
    echo "$LOG_DIR_RESULT" >&2
    exit 1
  fi

  LOG_DIR="$(printf '%s\n' "$LOG_DIR_RESULT" | awk 'NF { print; exit }')"

  if [[ -n "$LOG_DIR" && -d "$LOG_DIR" ]]; then
    NEWEST_LOG="$(ls -1t "$LOG_DIR" 2>/dev/null | head -n 1 || true)"
    if [[ -n "$NEWEST_LOG" ]]; then
      LOG_FILE="$LOG_DIR/$NEWEST_LOG"
    fi
  fi
fi

if [[ -z "$LOG_FILE" ]]; then
  LOG_MODE_SQL="
SELECT
  current_setting('logging_collector'),
  current_setting('log_destination'),
  current_setting('log_directory'),
  current_setting('data_directory');
"

  LOG_MODE_RESULT="$($PSQL_BIN "${PSQL_ARGS[@]}" -X -A -t -q -F '|' -c "$LOG_MODE_SQL" 2>/dev/null || true)"

  echo "Error: unable to determine PostgreSQL log file location." >&2
  echo "Tip: pass connection args, e.g. -h localhost -p 5432 -d bluebox -U postgres" >&2
  echo "Tip: or set/export DBA_FLAGS in your shell profile." >&2

  if [[ -n "$LOG_MODE_RESULT" ]]; then
    IFS='|' read -r LOGGING_COLLECTOR LOG_DESTINATION LOG_DIRECTORY DATA_DIRECTORY <<< "$LOG_MODE_RESULT"
    echo "Detected logging settings:" >&2
    echo "  logging_collector=$LOGGING_COLLECTOR" >&2
    echo "  log_destination=$LOG_DESTINATION" >&2
    echo "  log_directory=$LOG_DIRECTORY" >&2
    echo "  data_directory=$DATA_DIRECTORY" >&2

    if [[ "$LOGGING_COLLECTOR" == "off" && "$LOG_DESTINATION" == *stderr* ]]; then
      echo "PostgreSQL is configured to log to stderr without file collection, so there is no DB log file to tail." >&2
      echo "Use your service/container logs (for example, docker logs) or enable logging_collector to write log files." >&2
    fi
  fi

  exit 1
fi

if [[ ! -f "$LOG_FILE" ]]; then
  echo "Error: resolved log file does not exist: $LOG_FILE" >&2
  exit 1
fi

echo "Tailing $LINES lines from: $LOG_FILE"
tail -n "$LINES" "$LOG_FILE"
