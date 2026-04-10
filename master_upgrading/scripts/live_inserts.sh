#!/bin/bash
# ══════════════════════════════════════════════════════
#  live_inserts.sh  —  Continuously insert random orders
#  into demo_shop so you can watch replication in action.
#  Run on the PRIMARY.
# ══════════════════════════════════════════════════════

PG_VERSION=${PG_VERSION:-15}
BIN=/usr/lib/postgresql/${PG_VERSION}/bin
PSQL="sudo -u postgres $BIN/psql -U postgres -d demo_shop"
INTERVAL=${1:-2}   # seconds between inserts (default 2)

echo "Inserting a random order every ${INTERVAL}s — Ctrl+C to stop"
echo ""

i=1
while true; do
  RESULT=$($PSQL -t -c "
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
    SELECT format('  Order #%s | customer_id=%s product_id=%s qty=%s total=\$%s  [%s]',
                  id, customer_id, product_id, quantity, total, status)
    FROM new_order;
  " 2>&1)

  echo "$(date '+%H:%M:%S')  insert $i  →  $RESULT"
  ((i++))
  sleep "$INTERVAL"
done
