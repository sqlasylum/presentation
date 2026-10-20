# ---- Stage 1: pull prebuilt, alpine/musl-compatible Grafana binaries ----
ARG GRAFANA_VERSION=11.4.0
FROM grafana/grafana-oss:${GRAFANA_VERSION} AS grafana

# ---- Stage 2: Bluebox app image with Grafana bundled in ----
FROM node:20-alpine
WORKDIR /app

# bash + su-exec are needed by docker-entrypoint.sh (runs two processes and
# drops privileges for Grafana); ca-certificates/tzdata are Grafana runtime deps.
RUN apk add --no-cache bash su-exec ca-certificates tzdata \
    && addgroup -S grafana && adduser -S -G grafana grafana

# Bring in Grafana's binaries, default config, and provisioning dirs
COPY --from=grafana /usr/share/grafana /usr/share/grafana
COPY --from=grafana /etc/grafana /etc/grafana

# Provision the Postgres datasource, pointed at the bluebox-18 container via
# the same PGHOST/PGPORT/PGUSER/PGPASSWORD/PGDATABASE env vars used by the app
COPY provisioning/datasources/postgres.yaml /etc/grafana/provisioning/datasources/postgres.yaml

# Provision the Prometheus datasource (scrapes postgres-exporter) and the
# bundled PostgreSQL monitoring dashboard that queries it
COPY provisioning/datasources/prometheus.yaml /etc/grafana/provisioning/datasources/prometheus.yaml
COPY provisioning/dashboards/dashboards.yaml /etc/grafana/provisioning/dashboards/dashboards.yaml
COPY provisioning/dashboards/json /etc/grafana/provisioning/dashboards/json

ENV GF_PATHS_HOME=/usr/share/grafana \
    GF_PATHS_CONFIG=/etc/grafana/grafana.ini \
    GF_PATHS_DATA=/var/lib/grafana \
    GF_PATHS_LOGS=/var/log/grafana \
    GF_PATHS_PLUGINS=/var/lib/grafana/plugins \
    GF_PATHS_PROVISIONING=/etc/grafana/provisioning \
    GF_SERVER_HTTP_PORT=3001

# Grafana's own port 3000 collides with the Bluebox app, so it's moved to
# 3001 above. Data/log/plugin dirs need to be writable by the grafana user.
RUN mkdir -p "$GF_PATHS_DATA" "$GF_PATHS_LOGS" "$GF_PATHS_PLUGINS" \
    && chown -R grafana:grafana "$GF_PATHS_DATA" "$GF_PATHS_LOGS" "$GF_PATHS_PLUGINS" \
       /usr/share/grafana /etc/grafana

COPY package.json ./
RUN npm install --omit=dev

COPY . .
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 3000 3001
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
