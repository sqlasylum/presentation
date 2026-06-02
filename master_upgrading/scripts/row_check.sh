#!/bin/bash
# ══════════════════════════════════════════════════════
#  row_check.sh  —  Watch the latest orders on the STANDBY
#  to confirm rows are arriving from replication.
#  Run on the STANDBY.
# ══════════════════════════════════════════════════════

PG_VERSION=${PG_VERSION:-15}
BIN=/usr/lib/postgresql/${PG_VERSION}/bin
PSQL="sudo -u postgres $BIN/psql -U postgres -d demo_shop"
INTERVAL=${1:-2}   # refresh interval in seconds (default 2)

watch -n "$INTERVAL" "$PSQL -c \
  'SELECT id, status, ordered_at FROM orders ORDER BY ordered_at DESC LIMIT 5;'"
