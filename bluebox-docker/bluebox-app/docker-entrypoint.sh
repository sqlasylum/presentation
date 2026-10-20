#!/bin/bash
#
# Entrypoint for the bluebox-app image: runs Grafana (unprivileged) and the
# Node.js app side-by-side. If either process exits, the container stops.
#
set -e

# Start Grafana in the background as the unprivileged "grafana" user
su-exec grafana:grafana /usr/share/grafana/bin/grafana-server \
    --homepath="${GF_PATHS_HOME:-/usr/share/grafana}" \
    --config="${GF_PATHS_CONFIG:-/etc/grafana/grafana.ini}" \
    "cfg:default.paths.data=${GF_PATHS_DATA:-/var/lib/grafana}" \
    "cfg:default.paths.logs=${GF_PATHS_LOGS:-/var/log/grafana}" \
    "cfg:default.paths.plugins=${GF_PATHS_PLUGINS:-/var/lib/grafana/plugins}" \
    "cfg:default.paths.provisioning=${GF_PATHS_PROVISIONING:-/etc/grafana/provisioning}" &
GRAFANA_PID=$!

# Start the Bluebox app in the background too, so we can watch both
node server.js &
APP_PID=$!

# Exit (and let Docker restart/report) as soon as either process dies
wait -n "$GRAFANA_PID" "$APP_PID"
EXIT_CODE=$?

kill "$GRAFANA_PID" "$APP_PID" 2>/dev/null || true
exit "$EXIT_CODE"
