#!/bin/bash
set -e

PG_VERSION=${PG_VERSION:-15}
PGDATA=/var/lib/postgresql/${PG_VERSION}/main
PG_BIN=/usr/lib/postgresql/${PG_VERSION}/bin
PGUSER=postgres

banner() {
  echo ""
  echo "══════════════════════════════════════════════════"
  echo "  $1"
  echo "══════════════════════════════════════════════════"
  echo ""
}

# ── Always start SSH ──────────────────────────────────────
service ssh start
echo "[entrypoint] SSH started — connect with: ssh -p 2222 postgres@localhost"

# ── PRIMARY ───────────────────────────────────────────────
if [ "$PG_ROLE" = "primary" ]; then
  banner "Starting as PRIMARY (PostgreSQL $PG_VERSION)"

  if [ ! -f "$PGDATA/PG_VERSION" ]; then
    echo "[primary] Initializing data directory: $PGDATA"
    mkdir -p "$PGDATA"
    chown postgres:postgres "$PGDATA"
    sudo -u $PGUSER $PG_BIN/initdb -D "$PGDATA" --encoding=UTF8 --locale=en_US.UTF-8 -A trust
  fi

  # Apply config files
  cp /config/postgresql.conf "$PGDATA/postgresql.conf"
  cp /config/pg_hba.conf     "$PGDATA/pg_hba.conf"
  mkdir -p "$PGDATA/log"
  chown postgres:postgres "$PGDATA/log"

  echo "[primary] Starting PostgreSQL..."
  sudo -u $PGUSER $PG_BIN/pg_ctl start -D "$PGDATA" -w -t 60 \
    -l "$PGDATA/log/postgresql.log"

  # One-time setup
  SETUP_FLAG="$PGDATA/.setup_done"
  if [ ! -f "$SETUP_FLAG" ]; then
    echo "[primary] Creating replication user..."
    sudo -u $PGUSER $PG_BIN/psql -U postgres \
      -c "CREATE USER replicator WITH REPLICATION ENCRYPTED PASSWORD 'replicator';"

    echo "[primary] Running init.sql (demo database)..."
    sudo -u $PGUSER $PG_BIN/psql -U postgres -f /scripts/init.sql

    touch "$SETUP_FLAG"
  fi

  banner "PRIMARY READY"
  echo "  PostgreSQL $PG_VERSION is running as READ-WRITE PRIMARY"
  echo ""
  echo "  From host machine:"
  echo "    SSH  →  ssh -p 2222 postgres@localhost   (password: postgres)"
  echo "    psql →  psql -h localhost -p 5432 -U postgres demo_shop"
  echo ""
  echo "  Useful scripts in /scripts:"
  echo "    check_status.sh        — show role, version, replication"
  echo "    live_inserts.sh        — stream inserts to demo_shop"
  echo "    watch_replication.sh   — live replication lag monitor"
  echo ""

  exec tail -f "$PGDATA/log/postgresql.log"

# ── STANDBY ───────────────────────────────────────────────
elif [ "$PG_ROLE" = "standby" ]; then
  banner "Starting as HOT STANDBY (PostgreSQL $PG_VERSION)"
  PRIMARY=${PRIMARY_HOST:-pg-primary}
  REPL_PASS=${REPL_PASSWORD:-replicator}

  echo "[standby] Waiting for primary at $PRIMARY ..."
  until $PG_BIN/pg_isready -h "$PRIMARY" -U postgres -t 2 > /dev/null 2>&1; do
    echo "  ... still waiting for $PRIMARY ..."
    sleep 3
  done
  echo "[standby] Primary is ready."

  # Wipe and re-seed from primary
  rm -rf "$PGDATA"
  mkdir -p "$(dirname $PGDATA)"
  chown postgres:postgres "$(dirname $PGDATA)"

  echo "[standby] Running pg_basebackup from $PRIMARY ..."
  sudo -u $PGUSER env PGPASSWORD="$REPL_PASS" \
    $PG_BIN/pg_basebackup \
      -h "$PRIMARY" \
      -U replicator \
      -D "$PGDATA" \
      -Fp -Xs -R -P \
      --checkpoint=fast \
      -l "initial_standby_backup"

  # Ensure log directory exists
  mkdir -p "$PGDATA/log"
  chown postgres:postgres "$PGDATA/log"

  echo "[standby] Starting PostgreSQL as hot standby..."
  sudo -u $PGUSER $PG_BIN/pg_ctl start -D "$PGDATA" -w -t 60 \
    -l "$PGDATA/log/postgresql.log"

  banner "HOT STANDBY READY"
  echo "  PostgreSQL $PG_VERSION is running as READ-ONLY STANDBY"
  echo "  Streaming WAL from: $PRIMARY"
  echo ""
  echo "  From host machine:"
  echo "    SSH  →  ssh -p 2223 postgres@localhost   (password: postgres)"
  echo "    psql →  psql -h localhost -p 5433 -U postgres demo_shop"
  echo ""
  echo "  Useful scripts in /scripts:"
  echo "    check_status.sh     — show role, version, replication"
  echo "    promote_standby.sh  — promote this node to primary"
  echo ""

  exec tail -f "$PGDATA/log/postgresql.log"

else
  echo "ERROR: PG_ROLE must be 'primary' or 'standby'. Got: '${PG_ROLE}'"
  exit 1
fi
