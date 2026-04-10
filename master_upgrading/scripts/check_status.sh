#!/bin/bash
# ══════════════════════════════════════════════════════
#  check_status.sh  —  Show server role, version, and
#  replication state.  Run on EITHER node.
# ══════════════════════════════════════════════════════

PG_VERSION=${PG_VERSION:-15}
BIN=/usr/lib/postgresql/${PG_VERSION}/bin
PSQL="sudo -u postgres $BIN/psql -U postgres"

# echo ""
# echo "── Server version ──────────────────────────────────"
# $PSQL -t -d demo_shop -c "SELECT version();"

echo ""
echo "── This node's role ──────────────────────────────────"
$PSQL -d demo_shop -t -c "
  SELECT CASE WHEN pg_is_in_recovery()
    THEN '  🟡  HOT STANDBY  (read-only, streaming from primary)'
    ELSE '  🟢  PRIMARY      (read-write)'
  END;"

echo ""
echo "── Recovery / WAL receiver info (standby only) ──────────────────────────────────"
$PSQL -x -c "SELECT * FROM pg_stat_wal_receiver;" 2>/dev/null || true

echo ""
echo "── Replication senders (primary only) ──────────────────────────────────"
$PSQL -x -c "
  SELECT client_addr, application_name, state,
         sent_lsn, write_lsn, flush_lsn, replay_lsn,
         (sent_lsn - replay_lsn) AS lag_bytes
  FROM pg_stat_replication;" 2>/dev/null || true

echo ""
echo "── demo_shop row counts ──────────────────────────────────"
$PSQL -d demo_shop -c "
  SELECT 'customers' AS \"table\", COUNT(*) FROM customers
  UNION ALL SELECT 'products',    COUNT(*) FROM products
  UNION ALL SELECT 'orders',      COUNT(*) FROM orders;"

# echo ""
# echo "── Most recent 5 orders ──────────────────────────────────"
# $PSQL -d demo_shop -c "
#   SELECT o.id, c.name AS customer, p.name AS product,
#          o.quantity, o.total, o.status, o.ordered_at
#   FROM orders o
#   JOIN customers c ON c.id = o.customer_id
#   JOIN products  p ON p.id = o.product_id
#   ORDER BY o.ordered_at DESC LIMIT 5;"

# echo ""







