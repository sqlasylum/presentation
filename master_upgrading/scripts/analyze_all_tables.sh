#!/bin/bash
# ══════════════════════════════════════════════════════
#  analyze_all_tables.sh  —  Refresh planner stats after upgrade
#
#  ▶ Run this ON THE UPGRADED NODE after PG16 is started.
#  Uses analyze-in-stages for faster post-upgrade readiness,
#  then progressively improves optimizer statistics quality.
# ══════════════════════════════════════════════════════

set -euo pipefail

PG_VERSION=${PG_VERSION:-16}
BIN=/usr/lib/postgresql/${PG_VERSION}/bin
VACUUMDB="sudo -u postgres $BIN/vacuumdb"
PSQL="sudo -u postgres $BIN/psql"

echo ""
echo "═══════════════════════════════════════════════"
echo "  Post-upgrade ANALYZE (PostgreSQL ${PG_VERSION})"
echo "═══════════════════════════════════════════════"

# Ensure we can connect before kicking off analyze.
$PSQL -U postgres -d postgres -c "SELECT version();"

echo ""
echo "Running: vacuumdb --all --analyze-in-stages --verbose"
$VACUUMDB --all --analyze-in-stages --verbose --echo -U postgres

echo ""
echo "ANALYZE complete across all databases."
echo ""
