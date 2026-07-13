# PostgreSQL Load Generator

A Python-based load testing tool for PostgreSQL databases.

## Setup

1. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

2. **Configure database connection:**
   - Copy `.env.example` to `.env`
   - Update the database credentials in `.env`

3. **Ensure your PostgreSQL database is running:**
   - Host: localhost
   - Port: 5433
   - Database: bluebox

## Usage

### List available profiles:
```bash
python load_generator.py --list-profiles
```

### Basic usage (default profile):
```bash
python load_generator.py
```

This will run a 60-second load test with 5 threads using the default profile, each performing ~10 operations per second.

### Using a specific profile:
```bash
python load_generator.py --profile default
```

### Custom duration and threads:
```bash
python load_generator.py --duration 120 --threads 10 --ops-per-second 20 --profile default
```

### Command-line options:
- `--duration`: Test duration in seconds (default: 60)
- `--threads`: Number of concurrent threads (default: 5)
- `--ops-per-second`: Target operations per second per thread (default: 10)
- `--profile`: Load test profile to use (default: default)
- `--list-profiles`: List all available profiles and exit

## What it does

The load generator:
1. Creates a test table called `load_test` with indexes
2. Performs mixed workload operations based on the selected profile:
   - **INSERT**: Adds new records
   - **SELECT**: Various query types (simple, aggregate, joins)
   - **UPDATE**: Modifies existing records
   - **DELETE**: Removes old records (when count > 1000)

3. Provides real-time statistics and final summary

## Profiles

The load generator uses profiles to define different workload patterns. Each profile specifies:
- Operations to perform
- Relative weights for each operation
- Target table

### Default Profile

The default profile provides a balanced mix of operations, weighted towards reads:
- SELECT: 50% (read-heavy)
- INSERT: 20%
- UPDATE: 20%
- DELETE: 10%

### Adding New Profiles

To add a new profile, edit the `PROFILES` dictionary in `load_generator.py`:

```python
PROFILES = {
    'default': {
        'name': 'Default Load Profile',
        'description': 'Balanced mix of read and write operations',
        'operations': ['insert', 'select', 'update', 'delete'],
        'weights': [2, 5, 2, 1],
        'table': 'load_test'
    },
    'read-heavy': {
        'name': 'Read-Heavy Profile',
        'description': 'Primarily SELECT operations for read testing',
        'operations': ['insert', 'select'],
        'weights': [1, 9],
        'table': 'load_test'
    }
}
```

## Operation Distribution

Operations are weighted to simulate realistic workload:
- SELECT: 50% (read-heavy)
- INSERT: 20%
- UPDATE: 20%
- DELETE: 10%

## Example Output

```
============================================================
Starting Load Test
============================================================
Profile: Default Load Profile
Description: Balanced mix of read and write operations
Duration: 60 seconds
Threads: 5
Target ops/sec per thread: 10
Database: bluebox at localhost:5433
============================================================

✓ Test table 'load_test' initialized
[5.0s] Operations: 247 (49.4 ops/sec)
[10.0s] Operations: 501 (50.1 ops/sec)
...

============================================================
Load Test Complete
============================================================
Duration: 60.02 seconds
Total Operations: 3005
Average ops/sec: 50.07

Breakdown:
  Inserts: 601
  Selects: 1502
  Updates: 602
  Deletes: 300
  Errors: 0
============================================================
```

## Notes

- The script automatically creates the necessary test table and indexes
- Old records are automatically cleaned up when count exceeds 1000
- All operations are properly committed/rolled back
- Thread-safe statistics tracking
