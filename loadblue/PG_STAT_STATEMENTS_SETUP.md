# pg_stat_statements Configuration Guide

## Overview
`pg_stat_statements` is a PostgreSQL extension that tracks planning and execution statistics of all SQL statements executed by the server.

## Setup Steps

### 1. Enable in postgresql.conf

**Option A: Automated (Recommended)**

Use the provided script to automatically modify your postgresql.conf:

**Windows:**
```powershell
.\add_pg_stat_statements.ps1
# Or specify path:
.\add_pg_stat_statements.ps1 -ConfigPath "C:\Program Files\PostgreSQL\18\data\postgresql.conf"
```

**Linux/Mac:**
```bash
chmod +x add_pg_stat_statements.sh
./add_pg_stat_statements.sh
# Or specify path:
./add_pg_stat_statements.sh /etc/postgresql/16/main/postgresql.conf
```

The script will:
- Automatically find your postgresql.conf (or use the provided path)
- Create a backup before making changes
- Add or update the `shared_preload_libraries` setting
- Preserve any existing values in the setting

**Option B: Manual**

Add to your `postgresql.conf` file (typically in the PostgreSQL data directory):

```ini
# Load the extension
shared_preload_libraries = 'pg_stat_statements'

# Optional: Configuration parameters
pg_stat_statements.max = 10000              # Maximum number of statements tracked
pg_stat_statements.track = all              # Track all statements (all, top, none)
pg_stat_statements.track_utility = on       # Track utility commands
pg_stat_statements.track_planning = on      # Track planning time
```

### 2. Restart PostgreSQL
After modifying `postgresql.conf`, restart PostgreSQL:

**Windows (if running as service):**
```powershell
Restart-Service postgresql-x64-16  # Adjust name as needed
```

**Or stop/start manually:**
```powershell
pg_ctl restart -D "C:\PostgreSQL\data"
```

### 3. Create the Extension
Run the setup script to create the extension in your database:

```bash
psql -h localhost -p 5433 -U postgres -d bluebox -f setup_pg_stat_statements.sql
```

Or manually:
```sql
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
```

## Using the Scripts

### Configuration Scripts
**File:** `add_pg_stat_statements.ps1` (Windows) / `add_pg_stat_statements.sh` (Linux/Mac)
- Automatically modifies postgresql.conf
- Creates backup before making changes
- Adds pg_stat_statements to shared_preload_libraries
- Safely handles existing configurations

### Setup Script
**File:** `setup_pg_stat_statements.sql`
- Creates the pg_stat_statements extension
- Verifies installation
- Shows current settings

### Query Script  
**File:** `query_pg_stat_statements.sql`
- View top queries by execution time
- View most frequently called queries
- View queries with highest time variability
- Summary statistics

### Reset Script
**File:** `reset_pg_stat_statements.sql`
- Clears all accumulated statistics
- Useful when starting a new test

## Example Workflow for Load Testing

```bash
# 1. Configure postgresql.conf (first time only)
.\add_pg_stat_statements.ps1

# 2. Restart PostgreSQL
Restart-Service <postgres-service-name>

# 3. Create extension in database (first time only)
psql -h localhost -p 5433 -U postgres -d bluebox -f setup_pg_stat_statements.sql

# 4. Reset statistics before test
psql -h localhost -p 5433 -U postgres -d bluebox -f reset_pg_stat_statements.sql

# 5. Run load test
C:/loadblue/.venv/Scripts/python.exe load_generator.py --duration 60 --threads 5

# 6. Query statistics
psql -h localhost -p 5433 -U postgres -d bluebox -f query_pg_stat_statements.sql
```

## Useful Queries

### View real-time during load test:
```sql
SELECT 
    LEFT(query, 60) AS query,
    calls,
    ROUND(mean_exec_time::numeric, 2) AS avg_ms
FROM pg_stat_statements
WHERE query LIKE '%load_test%'
ORDER BY calls DESC;
```

### Find slow queries:
```sql
SELECT 
    LEFT(query, 100) AS query,
    calls,
    ROUND(max_exec_time::numeric, 2) AS max_ms,
    ROUND(mean_exec_time::numeric, 2) AS avg_ms
FROM pg_stat_statements
WHERE mean_exec_time > 10  -- slower than 10ms
ORDER BY mean_exec_time DESC;
```

## Important Notes

- Extension must be created per database
- Requires superuser privileges to install
- Statistics persist across database restarts (unless reset)
- Tracked queries are normalized (parameter values replaced with placeholders)
- Limited by `pg_stat_statements.max` setting (oldest queries are discarded)
