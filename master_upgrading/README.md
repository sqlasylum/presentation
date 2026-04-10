# PostgreSQL Upgrade Demo

A self-contained Docker environment demonstrating a PostgreSQL **Primary / Hot Standby** setup and a live **PG15 → PG16 major version upgrade** using failover promotion. Built for presentation use.

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     Docker Network (172.28.0.0/24)      │
│                                                         │
│   ┌───────────────────┐       ┌───────────────────┐    │
│   │    pg-primary      │──WAL─▶│    pg-standby     │    │
│   │  172.28.0.10       │       │  172.28.0.11      │    │
│   │  PostgreSQL 15     │       │  PostgreSQL 15    │    │
│   │  READ + WRITE      │       │  READ ONLY        │    │
│   └───────────────────┘       └───────────────────┘    │
│   SSH:  localhost:2222         SSH:  localhost:2223      │
│   psql: localhost:5432         psql: localhost:5433      │
└─────────────────────────────────────────────────────────┘
```

Both containers have **SSH access** so you can log in and run commands directly during a live demo.

---

## Prerequisites

- **[Docker Desktop](https://www.docker.com/products/docker-desktop/)** — or —
- **[Rancher Desktop](https://rancherdesktop.io/)** (see runtime note below)
- Ports `5432`, `5433`, `2222`, `2223` free on your host machine

---

## Rancher Desktop — Choose Your Runtime

Rancher Desktop supports two container runtimes. Pick one in **Preferences → Container Engine** before running these commands.

| Runtime | CLI to use | Notes |
|---|---|---|
| **dockerd (moby)** | `docker` | Same commands as Docker Desktop — recommended for simplicity |
| **containerd** | `nerdctl` | Drop-in replacement; swap `docker` → `nerdctl` in every command |

> If you switch runtimes after building, run the build command again.

---

## Quick Start

**Docker Desktop or Rancher Desktop (dockerd):**
```bash
# 1. Build images and start both containers
docker compose up --build -d

# 2. Watch startup logs (standby waits for primary to be healthy)
docker compose logs -f
```

**Rancher Desktop (containerd / nerdctl):**
```bash
# 1. Build images and start both containers
nerdctl compose up --build -d

# 2. Watch startup logs
nerdctl compose logs -f
```

**SSH and psql — same for both runtimes:**
```bash
# SSH into primary (password: postgres)
ssh -p 2222 postgres@localhost

# SSH into standby (password: postgres)
ssh -p 2223 postgres@localhost
```

### Connect via psql (from host)

```bash
# Primary (read-write)
psql -h localhost -p 5432 -U postgres demo_shop

# Standby (read-only)
psql -h localhost -p 5433 -U postgres demo_shop
```

---

## Credentials

| | Value |
|---|---|
| SSH password (both nodes) | `postgres` |
| PostgreSQL superuser | `postgres` / `postgres` |
| Replication user | `replicator` / `replicator` |

---

## Demo Database — `demo_shop`

Created automatically on first startup. Contains three related tables:

| Table | Description |
|---|---|
| `customers` | 7 seeded customers with name, email, city |
| `products` | 7 seeded products with price, stock, category |
| `orders` | 10 seeded orders + live inserts during demo |

---

## Scripts (inside containers at `/scripts`)

| Script | Run on | Purpose |
|---|---|---|
| `check_status.sh` | Either node | Show server version, role (primary/standby), replication state, and row counts |
| `live_inserts.sh` | Primary | Continuously insert random orders every 2s — shows replication flowing |
| `watch_replication.sh` | Primary | Live `watch` view of WAL lag and replication sender stats |
| `promote_standby.sh` | Standby | Promote standby → primary (Phase 1 of upgrade) |
| `upgrade_to_pg16.sh` | Old primary | Run `pg_upgrade` PG15 → PG16 with `--link` mode (Phase 2) |
| `rebuild_standby.sh` | Standby | Re-seed from upgraded primary and restart as PG16 hot standby (Phase 3) |

Run any script with:
```bash
bash /scripts/<script-name>.sh
```

---

## Upgrade Walkthrough

The upgrade follows a **rolling failover** pattern — no data loss, minimal downtime window.

### Phase 0 — Normal replication (baseline)

```bash
# On primary — show role and data
bash /scripts/check_status.sh

# On primary — start streaming inserts
bash /scripts/live_inserts.sh

# On standby — confirm rows are arriving
watch -n 2 "psql -U postgres -d demo_shop -c \
  'SELECT id, status, ordered_at FROM orders ORDER BY ordered_at DESC LIMIT 5;'"

# On primary — watch WAL lag
bash /scripts/watch_replication.sh
```

### Phase 1 — Promote standby → new primary

```bash
# On standby
bash /scripts/promote_standby.sh

# Confirm flip
bash /scripts/check_status.sh
# → Role: PRIMARY
```

App connections / VIP should now point to **pg-standby (port 5433)**.

### Phase 2 — Upgrade old primary PG15 → PG16

```bash
# On pg-primary (the now-idle original primary)
bash /scripts/upgrade_to_pg16.sh
# Runs: initdb PG16 → pg_upgrade --link → starts PG16
```

### Phase 3 — Re-establish replication on PG16

```bash
# On pg-standby — re-seed from the upgraded pg-primary
bash /scripts/rebuild_standby.sh

# Verify both nodes
bash /scripts/check_status.sh
# → PostgreSQL 16, Role: HOT STANDBY
```

Both nodes now run **PostgreSQL 16** with streaming replication restored.

### Final state

```
pg-primary  — PostgreSQL 16, HOT STANDBY  (was upgraded)
pg-standby  — PostgreSQL 16, PRIMARY      (was promoted)
```

Optionally flip the VIP / DNS back to pg-primary and go through the same promotion cycle to restore the original layout.

---

## File Structure

```
.
├── Dockerfile                   # Ubuntu + PG15 + PG16 binaries + SSH
├── docker-compose.yml           # Primary and standby services
├── entrypoint.sh                # Container startup logic (primary vs standby)
│
├── config/
│   ├── postgresql.conf          # Replication-ready server config (primary)
│   └── pg_hba.conf              # Auth rules — allows replication from Docker network
│
├── scripts/
│   ├── init.sql                 # Creates demo_shop DB, tables, and seed data
│   ├── check_status.sh          # Show role, version, replication, row counts
│   ├── live_inserts.sh          # Stream random orders to primary
│   ├── watch_replication.sh     # Live WAL lag monitor (run on primary)
│   ├── promote_standby.sh       # Promote this node to primary
│   ├── upgrade_to_pg16.sh       # pg_upgrade PG15 → PG16 on old primary
│   └── rebuild_standby.sh       # Re-establish PG16 standby after upgrade
│
├── demo_script.md               # Step-by-step presenter walkthrough
└── pg_upgrade_diagram.html      # Visual diagram of the upgrade phases (open in browser)
```

---

## Useful One-Liners

```bash
# Is this node primary or standby?
psql -U postgres -c "SELECT pg_is_in_recovery();"
# f = PRIMARY    t = STANDBY

# Replication lag (run on primary)
psql -U postgres -c \
  "SELECT client_addr, state, (sent_lsn - replay_lsn) AS lag_bytes FROM pg_stat_replication;"

# WAL receiver status (run on standby)
psql -U postgres -c "SELECT * FROM pg_stat_wal_receiver;"

# Stop and remove everything (including volumes)
docker compose down -v        # Docker Desktop / Rancher Desktop (dockerd)
nerdctl compose down -v       # Rancher Desktop (containerd)
```

---

## Suggested Terminal Layout for Presentation

```
┌─────────────────────┬─────────────────────┐
│  Terminal A         │  Terminal B         │
│  SSH → primary      │  SSH → standby      │
│  live_inserts.sh    │  watch orders       │
├─────────────────────┴─────────────────────┤
│  Terminal C — host                        │
│  docker compose logs -f                   │
│  (or: nerdctl compose logs -f)            │
└───────────────────────────────────────────┘
```
