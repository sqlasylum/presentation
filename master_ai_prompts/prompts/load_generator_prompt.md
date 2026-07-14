# Prompt: PostgreSQL Load Generator

## Task
Create a Python script called `load_generator.py` that generates configurable load against a PostgreSQL database using concurrent threads. The script is used to produce realistic query traffic for observability and performance testing purposes (e.g., populating `pg_stat_statements`).

---

## Dependencies
- `psycopg` (psycopg3, `psycopg[binary]>=3.1.0`) — PostgreSQL driver
- `python-dotenv==1.0.0` — load database credentials from a `.env` file
- Standard library: `time`, `random`, `threading`, `os`, `datetime`, `argparse`

---

## Database Configuration
- Read connection parameters from environment variables using `python-dotenv`.
- Variables: `DB_HOST` (default `localhost`), `DB_PORT` (default `5433`), `DB_NAME` (default `bluebox`), `DB_USER` (default `postgres`), `DB_PASSWORD` (default empty string).
- Store these in a `DB_CONFIG` dict.

---

## Load Profiles
- Define a `PROFILES` dict at the module level.
- Each profile is a dict with keys: `name`, `description`, `operations` (list of strings), `weights` (list of ints matching operations), `table` (string).
- Include one active profile called `default`:
  - Name: `"Default Load Profile"`
  - Description: `"Balanced mix of read and write operations"`
  - Operations: `['insert', 'select', 'update', 'delete']`
  - Weights: `[2, 5, 2, 1]` (favours reads)
  - Table: `"load_test"`
- Add commented-out example of a `read-heavy` profile for future reference.

---

## `LoadGenerator` Class

### `__init__(self, config, profile='default')`
- Store config and profile name.
- Look up the profile from `PROFILES`, falling back to `default`.
- Initialise a `stats` dict: `inserts`, `selects`, `updates`, `deletes`, `errors` — all starting at `0`.
- Create a `threading.Lock()` for thread-safe stat updates.

### `get_connection(self)`
- Open and return a new `psycopg.connect(...)` using the stored config.

### `initialize_table(self)`
- Create `load_test` table if it does not exist:
  - Columns: `id SERIAL PRIMARY KEY`, `name VARCHAR(100)`, `value INTEGER`, `data TEXT`, `created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP`, `updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP`
- Create indexes on `name` and `value` (both `IF NOT EXISTS`).
- Print a confirmation message on success.

### `perform_insert(self, conn)`
- Insert one row with a random `name` (`test_NNNN`), random `value` (1–1000), and random `data` string.
- Increment `stats['inserts']` on success; increment `stats['errors']` and rollback on failure.

### `perform_select(self, conn)`
- Randomly choose one of three query types: `simple`, `aggregate`, or `join`:
  - **simple**: `SELECT * FROM load_test WHERE value > %s LIMIT 10`
  - **aggregate**: `SELECT COUNT(*), AVG(value), MAX(value) FROM load_test`
  - **join** (self-join simulation): join `load_test` to itself on `value`, `LIMIT 10`
- Fetch results. Increment `stats['selects']`; increment `stats['errors']` on failure (no rollback needed).

### `perform_update(self, conn)`
- Update rows matching a random `value` with a new random `value` and set `updated_at = CURRENT_TIMESTAMP`.
- Increment `stats['updates']` on success; increment `stats['errors']` and rollback on failure.

### `perform_delete(self, conn)`
- First check the row count. Only delete if count exceeds 1000.
- Delete the 100 oldest rows by `created_at` using a subquery with `ORDER BY created_at LIMIT 100`.
- Increment `stats['deletes']` on success; increment `stats['errors']` and rollback on failure.

### `worker(self, duration, operations_per_second)`
- Open one connection per thread.
- Loop until `time.time()` exceeds `start + duration`.
- On each iteration, pick an operation using `random.choices` with the profile's `operations` and `weights`.
- Dispatch to the appropriate `perform_*` method.
- Sleep `1.0 / operations_per_second` between operations if `operations_per_second > 0`.
- Always close the connection in a `finally` block.

### `run(self, duration=60, num_threads=5, ops_per_second=10)`
- Print a header block showing profile name, description, duration, thread count, target ops/sec per thread, and DB host/port/name.
- Call `initialize_table()`.
- Spawn `num_threads` daemon threads each running `worker(duration, ops_per_second)`.
- Every 5 seconds while threads are alive, print elapsed time, total operation count, and rolling ops/sec.
- After all threads join, print a final summary: elapsed time, total ops, average ops/sec, and a breakdown of inserts/selects/updates/deletes/errors.

---

## `main()` — CLI Entry Point
Use `argparse` with the following arguments:

| Argument | Type | Default | Description |
|---|---|---|---|
| `--duration` | int | 60 | Test duration in seconds |
| `--threads` | int | 5 | Number of concurrent threads |
| `--ops-per-second` | int | 10 | Target ops/sec per thread |
| `--profile` | str | `default` | Profile name (choices from `PROFILES` keys) |
| `--list-profiles` | flag | — | Print all profiles and exit |

- If `--list-profiles` is passed, print each profile's key, name, description, operations, and weights, then return.
- Otherwise instantiate `LoadGenerator(DB_CONFIG, profile=args.profile)` and call `.run(...)`.
- Wrap in try/except; on error print a helpful message reminding the user to check that PostgreSQL is running, the database exists, and credentials are set in `.env`.

---

## Notes
- All stat increments must be inside `with self.lock:` blocks to be thread-safe.
- Each worker thread uses its own connection (no connection sharing across threads).
- The script should be runnable directly: guard `main()` with `if __name__ == '__main__':`.
