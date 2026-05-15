#!/bin/bash
# Script to run pg_basebackup and store the backup in /mnt/data/backups/base/pg-YYYY-MM-DD_HHMMSS
# Should be run on a schedule via cron to create regular backups of the PostgreSQL database.
# Seperate script (remove_base_backups.sh) should be used to remove old backups after a certain number of days.

# Command-line examples to run this script manually:
#   Local Unix socket (recommended):
#   PGUSER=postgres BACKUP_ROOT=/mnt/data/backups/base ./base_backup.sh
#
#   TCP without SSL (for servers not configured for SSL):
#   PGHOST=127.0.0.1 PGPORT=5432 PGUSER=postgres PGSSLMODE=disable BACKUP_ROOT=/mnt/data/backups/base MAX_RATE=25M ./base_backup.sh
#
#   TCP with SSL required (only if server supports SSL):
#   PGHOST=127.0.0.1 PGPORT=5432 PGUSER=postgres PGSSLMODE=require BACKUP_ROOT=/mnt/data/backups/base MAX_RATE=25M ./base_backup.sh

# Simple Tcp version without env vars 
# OF=pg-$(date +%F_%H%M%S)
# pg_basebackup -D /mnt/data/backups/base/$OF -d 'postgres://<user>:<pwd>@localhost:5432' --progress --max-rate=25M
# echo "Finished"


set -euo pipefail

OF="pg-$(date +%F_%H%M%S)"
BACKUP_ROOT="${BACKUP_ROOT:-/mnt/data/backups/base}"
BACKUP_DIR="$BACKUP_ROOT/$OF"

# Default to Unix socket so local backups do not depend on host replication pg_hba rules.
PGHOST="${PGHOST:-/var/run/postgresql}"
PGPORT="${PGPORT:-5432}"
PGUSER="${PGUSER:-postgres}"
PGDATABASE="${PGDATABASE:-postgres}"
MAX_RATE="${MAX_RATE:-25M}"

mkdir -p "$BACKUP_DIR"

CONNINFO="host=$PGHOST port=$PGPORT user=$PGUSER dbname=$PGDATABASE"
if [[ "$PGHOST" != /* ]]; then
	# If using TCP host/IP, honor sslmode via env (set PGSSLMODE=require when server enforces SSL).
	PGSSLMODE="${PGSSLMODE:-prefer}"
	CONNINFO="$CONNINFO sslmode=$PGSSLMODE"
fi

pg_basebackup \
	-D "$BACKUP_DIR" \
	-d "$CONNINFO" \
	--progress \
	--max-rate="$MAX_RATE"

echo "Finished: $BACKUP_DIR"

