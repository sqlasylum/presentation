#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# run_dba_task.sh  —  Run a DBA critical-task SQL script via psql
#
# Usage:
#   ./run_dba_task.sh -h <host> -d <database> -p <port> -U <username> -f <script>
#
# Available scripts (from dba_critical_tasks/):
#   check_activity
#   check_application_count
#   Check_connections
#   check_locks
#   Check_replication_slots
#   check_stats
#   check_vacuum_tables_needed
#   check_wait_events
#   Analyze_Query_toprentedmovies
#   All_scripts
#
# Example:
#   ./run_dba_task.sh -h localhost -d bluebox -p 5432 -U postgres -f check_locks
# ---------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/dba_critical_tasks"

# ---------- defaults --------------------------------------------------------
HOST="localhost"
DB="postgres"
PORT="5432"
USER="postgres"
FILE=""

# ---------- usage -----------------------------------------------------------
usage() {
    echo ""
    echo "Usage: $0 -f <script_name> [-h host] [-d database] [-p port] [-U username]"
    echo ""
    echo "  -f  SQL script name (with or without .sql extension)"
    echo "  -h  Database host        (default: localhost)"
    echo "  -d  Database name        (default: postgres)"
    echo "  -p  Port                 (default: 5432)"
    echo "  -U  Username             (default: postgres)"
    echo ""
    echo "Available scripts:"
    for f in "$SCRIPT_DIR"/*.sql; do
        echo "    $(basename "$f" .sql)"
    done
    echo ""
    exit 1
}

# ---------- parse args -------------------------------------------------------
while getopts ":h:d:p:U:f:" opt; do
    case $opt in
        h) HOST="$OPTARG"   ;;
        d) DB="$OPTARG"     ;;
        p) PORT="$OPTARG"   ;;
        U) USER="$OPTARG"   ;;
        f) FILE="$OPTARG"   ;;
        :) echo "Error: option -$OPTARG requires an argument." ; usage ;;
        *) echo "Error: unknown option -$OPTARG."              ; usage ;;
    esac
done

if [[ -z "$FILE" ]]; then
    echo "Error: -f <script_name> is required."
    usage
fi

# ---------- resolve file path ------------------------------------------------
# Strip .sql extension if supplied, then re-add it for the lookup
BASENAME="${FILE%.sql}"
SQL_FILE="$SCRIPT_DIR/${BASENAME}.sql"

if [[ ! -f "$SQL_FILE" ]]; then
    # Try a case-insensitive match in case the filename capitalisation differs
    MATCH=$(find "$SCRIPT_DIR" -maxdepth 1 -iname "${BASENAME}.sql" | head -n 1)
    if [[ -z "$MATCH" ]]; then
        echo "Error: script '${BASENAME}.sql' not found in $SCRIPT_DIR"
        echo ""
        echo "Available scripts:"
        for f in "$SCRIPT_DIR"/*.sql; do
            echo "    $(basename "$f" .sql)"
        done
        exit 1
    fi
    SQL_FILE="$MATCH"
fi

# ---------- run --------------------------------------------------------------
echo "-----------------------------------------------------------------------"
echo "  Host     : $HOST"
echo "  Database : $DB"
echo "  Port     : $PORT"
echo "  User     : $USER"
echo "  Script   : $SQL_FILE"
echo "-----------------------------------------------------------------------"
echo ""

psql \
    --host="$HOST" \
    --port="$PORT" \
    --dbname="$DB" \
    --username="$USER" \
    --file="$SQL_FILE"
