#!/bin/bash
# ══════════════════════════════════════════════════════
#  promote_standby.sh  —  Promote this node to PRIMARY.
#
#  ▶ Run this ON THE STANDBY (pg-standby container).
#
#  After promotion:
#    - This node becomes read-write
#    - Replication from old primary stops
#    - Redirect your app / VIP to this node
# ══════════════════════════════════════════════════════

PG_VERSION=${PG_VERSION:-15}
BIN=/usr/lib/postgresql/${PG_VERSION}/bin
PGDATA=/var/lib/postgresql/${PG_VERSION}/main

echo ""
echo "═══════════════════════════════════════════════"
echo "  PROMOTING STANDBY → PRIMARY"
echo "═══════════════════════════════════════════════"

# Verify we are actually a standby
IS_STANDBY=$(sudo -u postgres $BIN/psql -U postgres -t \
  -c "SELECT pg_is_in_recovery();" | tr -d ' \n')

if [ "$IS_STANDBY" != "t" ]; then
  echo ""
  echo "⚠  This node is already a PRIMARY — nothing to do."
  exit 0
fi

echo ""
echo "Current role: HOT STANDBY"
echo "Running pg_ctl promote ..."
echo ""

sudo -u postgres $BIN/pg_ctl promote -D "$PGDATA" -w

echo ""
echo "Waiting for promotion to complete ..."
sleep 2

sudo -u postgres $BIN/psql -U postgres -c "
  SELECT CASE WHEN pg_is_in_recovery()
    THEN 'STILL STANDBY — something went wrong'
    ELSE '✓  NOW PRIMARY — node is read-write'
  END AS result;"

echo ""
echo "Next step: redirect app connections / VIP to this node."
echo "Then run  upgrade_to_pg16.sh  on the OLD primary (pg-primary)."
echo ""
