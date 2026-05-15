#!/bin/bash
# Periodic INCREMENTAL backup using pgBackRest
# Intended schedule example (every 4 hours):
# 0 */4 * * * /path/to/pgbackrest_incremental.sh >> /var/log/pgbackrest_incr.log 2>&1

set -euo pipefail

# ---- Adjustable settings ----
STANZA="main"
PGBACKREST_BIN="pgbackrest"
LOG_TAG="pgbackrest-incr"

# Optional: uncomment to force a specific config file location.
# export PGBACKREST_CONFIG=/etc/pgbackrest/pgbackrest.conf
# -----------------------------

resolve_repo1_path() {
  local cfg=""
  local stanza_path=""
  local global_path=""

  if [[ -n "${PGBACKREST_CONFIG:-}" && -f "${PGBACKREST_CONFIG}" ]]; then
    cfg="${PGBACKREST_CONFIG}"
  elif [[ -f /etc/pgbackrest/pgbackrest.conf ]]; then
    cfg="/etc/pgbackrest/pgbackrest.conf"
  elif [[ -f /etc/pgbackrest.conf ]]; then
    cfg="/etc/pgbackrest.conf"
  fi

  if [[ -z "$cfg" ]]; then
    echo ""
    return
  fi

  stanza_path="$(awk -v stanza="$STANZA" '
    BEGIN { in_stanza=0 }
    $0 ~ "^[[:space:]]*\\[" stanza "\\][[:space:]]*$" { in_stanza=1; next }
    $0 ~ "^[[:space:]]*\\[[^]]+\\][[:space:]]*$" { in_stanza=0 }
    in_stanza && $0 ~ "^[[:space:]]*repo1-path[[:space:]]*=" {
      sub(/^[[:space:]]*repo1-path[[:space:]]*=[[:space:]]*/, "", $0)
      print $0
      exit
    }
  ' "$cfg")"

  if [[ -n "$stanza_path" ]]; then
    echo "$stanza_path"
    return
  fi

  global_path="$(awk '
    BEGIN { in_global=0 }
    $0 ~ "^[[:space:]]*\\[global\\][[:space:]]*$" { in_global=1; next }
    $0 ~ "^[[:space:]]*\\[[^]]+\\][[:space:]]*$" { in_global=0 }
    in_global && $0 ~ "^[[:space:]]*repo1-path[[:space:]]*=" {
      sub(/^[[:space:]]*repo1-path[[:space:]]*=[[:space:]]*/, "", $0)
      print $0
      exit
    }
  ' "$cfg")"

  echo "$global_path"
}

if ! command -v "$PGBACKREST_BIN" >/dev/null 2>&1; then
  echo "ERROR: pgbackrest binary not found in PATH." >&2
  exit 1
fi

START_TS="$(date '+%Y-%m-%d %H:%M:%S')"
REPO1_PATH="$(resolve_repo1_path)"

if [[ -n "$REPO1_PATH" ]]; then
  echo "[$START_TS] Backup destination (repo1-path): $REPO1_PATH"
else
  echo "[$START_TS] Backup destination (repo1-path): not found in config"
fi

echo "[$START_TS] Starting INCREMENTAL backup for stanza '$STANZA'"

"$PGBACKREST_BIN" \
  --stanza="$STANZA" \
  --type=incr \
  backup

END_TS="$(date '+%Y-%m-%d %H:%M:%S')"
echo "[$END_TS] INCREMENTAL backup completed successfully for stanza '$STANZA'"
