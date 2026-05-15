# Backup Scripts Documentation

This directory contains two backup approaches:

- Base backup scripts using `pg_basebackup`
- pgBackRest scripts for single-server and multi-server workflows

## File Inventory

### Base Backup Variation

- `base_backup.sh`
  - Creates a base backup with `pg_basebackup`.
  - Output directory pattern: `/mnt/data/backups/base/pg-YYYY-MM-DD_HHMMSS` (includes time so multiple backups per day are supported).
  - Connection defaults to Unix socket; override with `PGHOST`, `PGPORT`, `PGUSER`, `PGSSLMODE` env vars.
  - Includes transfer throttling controlled by `MAX_RATE` (default `25M`).
  - `BACKUP_ROOT` env var controls the destination root (default `/mnt/data/backups/base`).

- `remove_base_backups.sh`
  - Deletes older base backup directories using `find` and `-mtime`.
  - Retention is controlled by `daystokeep`.
  - Current delete path in script: `/mnt/data/backups/review_rocket/base/pg-2*`.

### pgBackRest Variation (Single Server)

- `pgbackrest.conf.sample`
  - Sample config for one stanza (`[main]`).
  - Defines global repository settings like `repo1-path` and retention values.

- `pgbackrest_full_nightly.sh`
  - Runs nightly FULL backup: `pgbackrest --stanza=main --type=full backup`.
  - Prints resolved `repo1-path` before backup starts.
  - Looks for config in this order:
    - `$PGBACKREST_CONFIG` (if set)
    - `/etc/pgbackrest/pgbackrest.conf`
    - `/etc/pgbackrest.conf`

- `pgbackrest_incremental.sh`
  - Runs periodic INCREMENTAL backup: `pgbackrest --stanza=main --type=incr backup`.
  - Prints resolved `repo1-path` before backup starts.
  - Uses the same config discovery order as the nightly script.

### pgBackRest Variation (Multi Server)

- `pgbackrest_multi.conf.sample`
  - Sample config for multiple stanzas.
  - Includes example stanzas:
    - `[db5450]` for localhost:5450
    - `[db5433]` for localhost:5433
  - Uses shared global repo and retention settings.

- `pgbackrest_multi.performance.conf.sample`
  - Performance-oriented variant of the multi-server config.
  - Enables `compress-type=zst`, `repo1-bundle=y`, `repo1-block=y`, `process-max=4`.
  - Enables async WAL archiving (`archive-async=y`) with a dedicated `spool-path`.
  - Tunes archive-push separately via `[global:archive-push]`.

- `pgbackrest_multi_nightly.sh`
  - Loops through `STANZAS` array and runs FULL backup for each stanza.
  - Current stanzas: `db5450`, `db5433`.
  - Prints resolved `repo1-path` for each stanza before running backup.

- `pgbackrest_multi_incremental.sh`
  - Loops through `STANZAS` array and runs INCREMENTAL backup for each stanza.
  - Current stanzas: `db5450`, `db5433`.
  - Prints resolved `repo1-path` for each stanza before running backup.

## Base vs pgBackRest Summary

- Base backup scripts (`pg_basebackup`)
  - Simpler to understand and run.
  - Manual retention handling with a separate cleanup script.
  - Geared toward direct directory snapshots.

- pgBackRest scripts
  - Built-in backup types (`full`, `incr`) and retention options.
  - Better for ongoing operational backups and scaling to multiple servers.
  - Config-driven repository destination (`repo1-path`) and stanza management.

## Scheduling Examples (cron)

- Single server nightly FULL (2 AM)
  - `0 2 * * * /path/to/pgbackrest_full_nightly.sh >> /var/log/pgbackrest_full.log 2>&1`

- Single server incremental every 4 hours
  - `0 */4 * * * /path/to/pgbackrest_incremental.sh >> /var/log/pgbackrest_incr.log 2>&1`

- Multi server nightly FULL (1:30 AM)
  - `30 1 * * * /path/to/pgbackrest_multi_nightly.sh >> /var/log/pgbackrest_multi_full.log 2>&1`

- Multi server incremental every 4 hours
  - `0 */4 * * * /path/to/pgbackrest_multi_incremental.sh >> /var/log/pgbackrest_multi_incr.log 2>&1`

## Adding More PostgreSQL Servers (pgBackRest Multi)

1. Add a new stanza in `pgbackrest_multi.conf.sample` (and real `pgbackrest.conf`) with `pg1-path`, `pg1-host`, `pg1-port`, `pg1-user`.
2. Add the stanza name to the `STANZAS` array in:
   - `pgbackrest_multi_nightly.sh`
   - `pgbackrest_multi_incremental.sh`
3. Initialize the stanza as needed in your environment:
   - `pgbackrest --stanza=<new_stanza> stanza-create`
4. Validate backup execution manually before relying on cron.



## Common pgBackRest Performance Commands

The following options are commonly used to improve backup/archiving performance. These come from the official pgBackRest documentation (command reference, configuration reference, and user guide).

### 1) Increase parallel workers (`process-max`)

- Why: parallel compression/transfer is usually the biggest speed gain.
- Rule of thumb from docs: start conservatively for backups (often up to ~25% of CPU), then benchmark.

- One-off command examples:
  - `pgbackrest --stanza=main --process-max=4 --type=full backup`
  - `pgbackrest --stanza=main --process-max=4 --type=incr backup`

- Config example:
  - `[global]`
  - `process-max=4`

### 2) Start backups immediately (`start-fast`)

- Why: forces a checkpoint so backup starts right away instead of waiting for the next regular checkpoint.

- One-off command example:
  - `pgbackrest --stanza=main --type=full --start-fast backup`

- Config example:
  - `[global]`
  - `start-fast=y`

### 3) Use faster compression (`compress-type=zst`)

- Why: pgBackRest recommends `zst` for much faster compression with similar ratio to `gz`.

- One-off command examples:
  - `pgbackrest --stanza=main --type=full --compress-type=zst backup`
  - `pgbackrest --stanza=main --type=incr --compress-type=zst backup`

- Config example:
  - `[global]`
  - `compress-type=zst`

### 4) Enable file bundling for repository performance (`repo1-bundle`)

- Why: combines many small files into bundles, often much faster on object stores and many filesystems.

- Config example:
  - `[global]`
  - `repo1-bundle=y`

### 5) Enable block incremental (`repo1-block`) with bundling

- Why: stores only changed file blocks for diff/incr backups, which improves speed and saves space.
- Requirement: `repo1-bundle=y` must be enabled first.

- Config example:
  - `[global]`
  - `repo1-bundle=y`
  - `repo1-block=y`

### 6) Enable asynchronous archiving (`archive-async`) for WAL throughput

- Why: archives WAL in batches and reuses connections; often a major WAL archiving speed improvement.
- Requirement: configure a local `spool-path`.

- Config example:
  - `[global]`
  - `archive-async=y`
  - `spool-path=/var/spool/pgbackrest`
  - `[global:archive-push]`
  - `process-max=2`

### 7) Tune archive compression separately (`[global:archive-push]`)

- Why: reduce WAL archiving CPU cost without changing backup compression policy.

- Config example:
  - `[global:archive-push]`
  - `compress-level=3`

### 8) Reduce load on primary (`backup-standby`)

- Why: run backups from standby instead of primary when available.

- Config example:
  - `[global]`
  - `backup-standby=prefer`

### 9) Useful health checks while tuning

- Verify config/archive path quickly:
  - `pgbackrest --stanza=main check`
- Show backup status and timings:
  - `pgbackrest --stanza=main info`
- JSON output for scripting/metrics:
  - `pgbackrest --stanza=main --output=json info`

### Suggested tuning order

1. Enable `start-fast` and increase `process-max` gradually.
2. Move from default compression to `compress-type=zst`.
3. Enable `repo1-bundle=y`.
4. Enable `repo1-block=y` (with bundling enabled).
5. Enable `archive-async=y` + `spool-path` and tune `[global:archive-push]`.

Always benchmark on your hardware and watch CPU, disk IOPS, WAL lag, and backup duration before and after each change.

