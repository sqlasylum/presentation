#!/usr/bin/env bash
# Host-side insert loop for failover demos.
# Usage:
#   ./host_live_inserts.sh primary [interval_seconds]
#   ./host_live_inserts.sh secondary [interval_seconds]
#
# Optional environment overrides:
#   DB_HOST, DB_NAME, DB_USER, PRIMARY_PORT, SECONDARY_PORT, PGCONNECT_TIMEOUT

set -u

ROLE="${1:-}"
INTERVAL="${2:-2}"

DB_HOST="${DB_HOST:-localhost}"
DB_NAME="${DB_NAME:-demo_shop}"
DB_USER="${DB_USER:-postgres}"
PRIMARY_PORT="${PRIMARY_PORT:-5450}"
SECONDARY_PORT="${SECONDARY_PORT:-5433}"
PGCONNECT_TIMEOUT="${PGCONNECT_TIMEOUT:-2}"

usage() {
  echo "Usage: $0 <primary|secondary> [interval_seconds]"
  echo ""
  echo "Examples:"
  echo "  $0 primary"
  echo "  $0 secondary 1"
  echo ""
  echo "Environment overrides:"
  echo "  DB_HOST=$DB_HOST DB_NAME=$DB_NAME DB_USER=$DB_USER"
  echo "  PRIMARY_PORT=$PRIMARY_PORT SECONDARY_PORT=$SECONDARY_PORT"
  exit 1
}

if [[ -z "$ROLE" ]]; then
  usage
fi

case "$ROLE" in
  primary|p)
    TARGET_LABEL="primary"
    DB_PORT="$PRIMARY_PORT"
    ;;
  secondary|standby|s)
    TARGET_LABEL="secondary"
    DB_PORT="$SECONDARY_PORT"
    ;;
  *)
    echo "Error: unknown target '$ROLE'"
    usage
    ;;
esac

SQL="
WITH new_order AS (
  INSERT INTO orders (customer_id, product_id, quantity, total, status)
  SELECT
    (random()*6+1)::int,
    (random()*6+1)::int,
    (random()*3+1)::int,
    round((random()*120+10)::numeric, 2),
    (ARRAY['pending','processing','shipped','completed'])[floor(random()*4+1)::int]
  RETURNING id, customer_id, product_id, quantity, total, status
)
SELECT format(
  'server_port=%s recovery=%s | Order #%s | customer_id=%s product_id=%s qty=%s total=$%s [%s]',
  current_setting('port'),
  pg_is_in_recovery(),
  id, customer_id, product_id, quantity, total, status
)
FROM new_order;
"

echo "Target: ${TARGET_LABEL} (${DB_HOST}:${DB_PORT})"
echo "Inserting a random order every ${INTERVAL}s from the host. Ctrl+C to stop."
echo ""

i=1
while true; do
  RESULT=$(PGCONNECT_TIMEOUT="$PGCONNECT_TIMEOUT" \
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
      -v ON_ERROR_STOP=1 -At -c "$SQL" 2>&1)
  STATUS=$?

  if [[ $STATUS -eq 0 ]]; then
    echo "$(date '+%H:%M:%S')  insert $i  -> [$TARGET_LABEL@$DB_HOST:$DB_PORT]  $RESULT"
    ((i++))
  else
    echo "$(date '+%H:%M:%S')  ERROR [$TARGET_LABEL@$DB_HOST:$DB_PORT]  $RESULT"
  fi

  sleep "$INTERVAL"
done
