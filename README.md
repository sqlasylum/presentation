# PostgreSQL Presentation Repository

This repository contains materials used in PostgreSQL presentations.  
Each top-level folder maps to a specific presentation topic and includes runnable scripts, demo assets, and reference SQL.

## Who This Is For

- DBAs who want practical monitoring and backup scripts
- Engineers learning PostgreSQL upgrade strategies
- Presenters who want reusable demo environments

## Repository At A Glance

### dba_critical_tasks/

Presentation focus: day-to-day DBA checks and operational triage.

What is inside:
- Reusable SQL scripts for active sessions, lock chains, wait events, replication slot lag, vacuum health, and stats checks
- A combined script ([dba_critical_tasks/All_scripts.sql](dba_critical_tasks/All_scripts.sql)) with many checks in one place
- Backup-focused subfolder ([dba_critical_tasks/backups/](dba_critical_tasks/backups/)) covering both `pg_basebackup` and `pgBackRest` workflows

Good starting points:
- [dba_critical_tasks/check_activity.sql](dba_critical_tasks/check_activity.sql)
- [dba_critical_tasks/check_locks.sql](dba_critical_tasks/check_locks.sql)
- [dba_critical_tasks/check_wait_events.sql](dba_critical_tasks/check_wait_events.sql)
- [dba_critical_tasks/backups/README.md](dba_critical_tasks/backups/README.md)

### master_upgrading/

Presentation focus: major version upgrade strategy using a live Primary/Standby failover model.

What is inside:
- Docker-based two-node PostgreSQL environment for demo use
- End-to-end PG15 -> PG16 upgrade walkthrough
- Scripts for role checks, live inserts, standby promotion, upgrade execution, and standby rebuild
- Presenter notes and visual artifacts

Good starting points:
- [master_upgrading/README.md](master_upgrading/README.md)
- [master_upgrading/demo_script.md](master_upgrading/demo_script.md)
- [master_upgrading/scripts/upgrade_to_pg16.sh](master_upgrading/scripts/upgrade_to_pg16.sh)


### master_ai_prompts/

Presentation focus: AI-assisted load testing and query performance analysis for PostgreSQL.

What is inside:
- Python-based load generator built with AI tooling for simulating realistic PostgreSQL workloads
- Configurable profiles for mixed read/write, read-heavy, and custom workloads
- `pg_stat_statements` setup and query scripts for capturing and analyzing slow queries during load runs
- Setup guides and reset scripts for the statistics extension

Good starting points:
- [master_ai_prompts/README.md](master_ai_prompts/README.md)
- [master_ai_prompts/load_generator.py](master_ai_prompts/load_generator.py)
- [master_ai_prompts/PG_STAT_STATEMENTS_SETUP.md](master_ai_prompts/PG_STAT_STATEMENTS_SETUP.md)

### DB Migrations to the Cloud/

Presentation focus: Steps you need to take to move from on Premise to the cloud for your Database. 

What is inside:
- Presentation files from the Webinar related to cloud migration. 

Link to file 
- [db_migrations_to_cloud.pdf](db_migrations_to_cloud.pdf)



## Root-Level Utilities

- [run_dba_task.sh](run_dba_task.sh): helper script that runs any SQL file in [dba_critical_tasks/](dba_critical_tasks/) with standard `psql` flags.

Example:

```bash
./run_dba_task.sh -h localhost -d postgres -p 5432 -U postgres -f check_locks
```

## Suggested First-Time Path

1. Read [dba_critical_tasks/backups/README.md](dba_critical_tasks/backups/README.md) to understand backup options and script intent.
2. Run one or two lightweight health checks from [dba_critical_tasks/](dba_critical_tasks/) using [run_dba_task.sh](run_dba_task.sh).
3. If you are interested in upgrades, launch the Docker demo in [master_upgrading/](master_upgrading/) and follow [master_upgrading/demo_script.md](master_upgrading/demo_script.md).
4. To simulate load and analyze query performance, follow [master_ai_prompts/README.md](master_ai_prompts/README.md) to set up and run the load generator.

## Prerequisites

- PostgreSQL client tools (`psql`) for SQL task scripts
- Bash shell environment
- Docker Desktop or Rancher Desktop for the upgrade demo in [master_upgrading/](master_upgrading/)
- Python 3 and `pip` for the load testing tool in [master_ai_prompts/](master_ai_prompts/)

## Notes

- Many scripts are intended for operational troubleshooting in non-production first. Validate against your environment before production use.
- Some SQL scripts include schema-specific filters (for example, hardcoded schema names). Adjust filters before running in your own databases.

