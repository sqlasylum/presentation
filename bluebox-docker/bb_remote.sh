#!/bin/bash
#
# Start Bluebox Postgres using the published image from ghcr.io/ryanbooz
#

set -euo pipefail

cd "$(dirname "$0")"

# Make sure any locally-exported BLUEBOX_IMAGE override doesn't leak in here,
# so start.sh falls back to its default remote image
# (ghcr.io/ryanbooz/bluebox-postgres).
unset BLUEBOX_IMAGE || true

exec ./start.sh
