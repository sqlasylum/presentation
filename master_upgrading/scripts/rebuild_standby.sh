#!/bin/bash
# ══════════════════════════════════════════════════════
#  rebuild_standby.sh  —  Re-establish streaming replication
#  after the upgrade.
#
#  ▶ Run this ON pg-standby AFTER:
#    1. pg-primary has been upgraded to PG16
#    2. pg-primary (now PG16) is running
#
#  This node will be re-seeded from the PG16 primary
#  and come up as a PG16 hot standby.
# ══════════════════════════════════════════════════════

NEW_VER=16
NEW_BIN=/usr/lib/postgresql/${NEW_VER}/bin
PGDATA=/var/lib/postgresql/${NEW_VER}/main
PRIMARY=${PRIMARY_HOST:-pg-primary}
REPL_PASS=${REPL_PASSWORD:-replicator}

echo ""
echo "═══════════════════════════════════════════════"
echo "  Re-establishing standby (PG${NEW_VER}) from $PRIMARY"
echo "═══════════════════════════════════════════════"

# ── Stop any running PG instance ─────────────────────
echo ""
echo "Step 1 of 4  →  Stop any running PostgreSQL ..."
for VER in 15 16; do
  D="/var/lib/postgresql/${VER}/main"
  B="/usr/lib/postgresql/${VER}/bin"
  if [ -f "$D/postmaster.pid" ]; then
    sudo -u postgres $B/pg_ctl stop -D "$D" -m fast 2>/dev/null || true
  fi
done
sleep 2

# ── Wait for PG16 primary ─────────────────────────────
echo ""
echo "Step 2 of 4  →  Waiting for PG16 primary at $PRIMARY ..."
until $NEW_BIN/pg_isready -h "$PRIMARY" -U postgres -t 2 > /dev/null 2>&1; do
  echo "  ... waiting ..."
  sleep 3
done
echo "  Primary is ready."

# ── pg_basebackup ─────────────────────────────────────
echo ""
echo "Step 3 of 4  →  Running pg_basebackup ..."
rm -rf "$PGDATA"
mkdir -p "$(dirname $PGDATA)"
chown postgres:postgres "$(dirname $PGDATA)"

PGPASSWORD="$REPL_PASS" sudo -u postgres \
  $NEW_BIN/pg_basebackup \
    -h "$PRIMARY" \
    -U replicator \
    -D "$PGDATA" \
    -Fp -Xs -R -P \
    --checkpoint=fast

mkdir -p "$PGDATA/log"
chown postgres:postgres "$PGDATA/log"

# ── Start PG16 standby ───────────────────────────────
echo ""
echo "Step 4 of 4  →  Starting hot standby ..."
sudo -u postgres $NEW_BIN/pg_ctl start -D "$PGDATA" -w -t 60 \
  -l "$PGDATA/log/postgresql.log"

echo ""
echo "═══════════════════════════════════════════════"
echo "  STANDBY READY  (PostgreSQL ${NEW_VER})"
echo "═══════════════════════════════════════════════"
sudo -u postgres $NEW_BIN/psql -U postgres -c "
  SELECT version();
  SELECT CASE WHEN pg_is_in_recovery()
    THEN '✓  Role: HOT STANDBY'
    ELSE '✗  Role: PRIMARY (unexpected)'
  END;"
echo ""
