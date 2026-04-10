# PostgreSQL Upgrade Demo — Presenter Script

## Quick Start

```bash
# Build and start both containers
docker compose up --build -d

# Watch startup logs
docker compose logs -f
```

---

## Terminal Layout (suggested split)

| Terminal | Purpose |
|---|---|
| **A** — host machine | docker compose commands |
| **B** — SSH into primary | psql, scripts |
| **C** — SSH into standby | psql, scripts |

```bash
# Open SSH sessions (password: postgres for both)
ssh -p 2222 postgres@localhost   # Terminal B — primary
ssh -p 2223 postgres@localhost   # Terminal C — standby
```

---

## Phase 0 — Show Normal Replication

**On primary (Terminal B):**
```bash
# Show version and role
bash /scripts/check_status.sh

# Start live inserts so the audience sees data flowing
bash /scripts/live_inserts.sh
```

**On standby (Terminal C) — open a second pane:**
```bash
# Show this node is read-only and receiving WAL
bash /scripts/check_status.sh

# Watch orders arriving in real-time
watch -n 2 "psql -U postgres -d demo_shop -c \
  'SELECT id, status, ordered_at FROM orders ORDER BY ordered_at DESC LIMIT 5;'"
```

**On primary (Terminal B) — open a second pane:**
```bash
# Watch replication lag live
bash /scripts/watch_replication.sh
```

---

## Phase 1 — Promote Standby to Primary

**Stop live inserts on primary** (Ctrl+C in Terminal B).

**On standby (Terminal C):**
```bash
# This node becomes the new read-write primary
bash /scripts/promote_standby.sh

# Confirm the flip
bash /scripts/check_status.sh
```

**Show the standby is now primary, old primary is isolated.**

---

## Phase 2 — Upgrade Old Primary (PG15 → PG16)

**On primary (Terminal B) — the old primary is now idle:**
```bash
# Walk through pg_upgrade in --link mode (fast, no file copy)
bash /scripts/upgrade_to_pg16.sh

# Verify PG16 is running
/usr/lib/postgresql/16/bin/psql -U postgres -c "SELECT version();"
```

---

## Phase 3 — Re-establish Replication (both on PG16)

**On standby node (Terminal C):**
```bash
# Re-seed from the new PG16 primary (pg-primary)
# Note: pg-standby's PRIMARY_HOST env still points to pg-primary
bash /scripts/rebuild_standby.sh

# Check final state
bash /scripts/check_status.sh
```

---

## Final State Check

**On original primary (Terminal B):**
```bash
bash /scripts/check_status.sh
# → PostgreSQL 16, Role: PRIMARY
```

**On standby (Terminal C):**
```bash
bash /scripts/check_status.sh
# → PostgreSQL 16, Role: HOT STANDBY
```

---

## Cleanup

```bash
docker compose down -v    # remove containers and volumes
```

---

## Key Commands Reference

```bash
# Connect to primary via psql (from host)
psql -h localhost -p 5432 -U postgres demo_shop

# Connect to standby via psql (from host, read-only)
psql -h localhost -p 5433 -U postgres demo_shop

# Check if a node is primary or standby
psql -U postgres -c "SELECT pg_is_in_recovery();"
# → f = PRIMARY   t = STANDBY

# Manually check replication lag (run on primary)
psql -U postgres -c "SELECT client_addr, state, (sent_lsn - replay_lsn) lag_bytes FROM pg_stat_replication;"

# Check WAL receiver status (run on standby)
psql -U postgres -c "SELECT * FROM pg_stat_wal_receiver;"
```

---

## Ports

| Service | PostgreSQL | SSH |
|---|---|---|
| pg-primary | localhost:5432 | `ssh -p 2222 postgres@localhost` |
| pg-standby | localhost:5433 | `ssh -p 2223 postgres@localhost` |

**Passwords:** `postgres` (postgres user, SSH), `replicator` (replication user)
