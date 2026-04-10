#!/bin/bash
# ══════════════════════════════════════════════════════
#  upgrade_to_pg16.sh  —  In-place upgrade PG15 → PG16
#
#  ▶ Run this ON THE OLD PRIMARY (pg-primary container)
#    AFTER the standby has been promoted and clients
#    have been redirected to the new primary.
# ══════════════════════════════════════════════════════

OLD_VER=15
NEW_VER=16
OLD_BIN=/usr/lib/postgresql/${OLD_VER}/bin
NEW_BIN=/usr/lib/postgresql/${NEW_VER}/bin
OLD_DATA=/var/lib/postgresql/${OLD_VER}/main
NEW_DATA=/var/lib/postgresql/${NEW_VER}/main

echo ""
echo "═══════════════════════════════════════════════"
echo "  pg_upgrade  PG${OLD_VER} → PG${NEW_VER}"
echo "═══════════════════════════════════════════════"

# ── Step 1: Stop PG15 if still running ───────────────
echo ""
echo "Step 1 of 5  →  Stop PostgreSQL ${OLD_VER} ..."
if sudo -u postgres $OLD_BIN/pg_ctl status -D "$OLD_DATA" > /dev/null 2>&1; then
  sudo -u postgres $OLD_BIN/pg_ctl stop -D "$OLD_DATA" -m fast
  echo "  PostgreSQL ${OLD_VER} stopped."
else
  echo "  PostgreSQL ${OLD_VER} was not running (OK)."
fi

# ── Step 2: Init new PG16 data directory ─────────────
echo ""
echo "Step 2 of 5  →  Initialize PG${NEW_VER} data directory ..."
if [ -d "$NEW_DATA" ]; then
  echo "  Removing previous PG${NEW_VER} data dir ..."
  rm -rf "$NEW_DATA"
fi
sudo -u postgres $NEW_BIN/initdb \
  -D "$NEW_DATA" \
  --encoding=UTF8 \
  --locale=en_US.UTF-8 \
  -A trust

# ── Step 3: pg_upgrade (--link = no file copy) ────────
echo ""
echo "Step 3 of 5  →  Running pg_upgrade (--link mode) ..."
echo "  This hard-links data files — very fast."
echo ""
cd /tmp
sudo -u postgres $NEW_BIN/pg_upgrade \
  -b "$OLD_BIN" \
  -B "$NEW_BIN" \
  -d "$OLD_DATA" \
  -D "$NEW_DATA" \
  --link

# ── Step 4: Copy / adjust config ─────────────────────
echo ""
echo "Step 4 of 5  →  Copying postgresql.conf and pg_hba.conf ..."
cp "$OLD_DATA/postgresql.conf" "$NEW_DATA/postgresql.conf"
cp "$OLD_DATA/pg_hba.conf"     "$NEW_DATA/pg_hba.conf"
chown postgres:postgres "$NEW_DATA/postgresql.conf" "$NEW_DATA/pg_hba.conf"
mkdir -p "$NEW_DATA/log"
chown postgres:postgres "$NEW_DATA/log"

# ── Step 5: Start PG16 ───────────────────────────────
echo ""
echo "Step 5 of 5  →  Starting PostgreSQL ${NEW_VER} ..."
sudo -u postgres $NEW_BIN/pg_ctl start -D "$NEW_DATA" -w -t 60 \
  -l "$NEW_DATA/log/postgresql.log"

echo ""
echo "═══════════════════════════════════════════════"
echo "  UPGRADE COMPLETE"
echo "═══════════════════════════════════════════════"
sudo -u postgres $NEW_BIN/psql -U postgres -c "SELECT version();"
echo ""
echo "Next step: run  rebuild_standby.sh  to re-establish replication."
echo ""
