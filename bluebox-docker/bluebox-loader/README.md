# Bluebox Loader

Profile-driven, multithreaded load testing service for Bluebox PostgreSQL.

The loader is a single service binary and is configured entirely by JSON profile files. Run it repeatedly with different profiles to emulate different applications and load shapes.

## Included Profiles

| Profile | Workload |
| --- | --- |
| `profiles/order-service-large-profile.json` | Mixed order workload: 400 sessions, 24 threads, weighted 60% inserts, 30% updates, and 10% inventory reports. |
| `profiles/shipping-service-small-profile.json` | Smaller mixed workload: 80 sessions, 8 threads, weighted 25% inserts, 25% updates, and 50% status-summary reports. |
| `profiles/ec2-order-service-sustained-profile.json` | Sustained mixed order workload: up to 50,000 sessions, 16 threads, 25-minute runtime limit, and a 55/35/10 insert/update/report mix. |
| `profiles/deadlock-service-profile.json` | Runs forced deadlock attempts between two transactions, with a 5-minute runtime limit and up to 40 sessions. |
| `profiles/idle-in-transaction-profile.json` | Holds a transaction idle for 2 seconds before running a status-summary report; 4 threads and up to 1,200 transactions. |
| `profiles/idle-in-transaction-profile_new.json` | Higher-throughput idle-in-transaction variant: 20 threads, 3 seconds idle, and a 5-minute runtime limit. It configures 2,000 sessions, which is the effective transaction cap because the runner uses the smaller of sessions and `max_transactions`. |
| `profiles/high-connections-readonly-profile.json` | Read-only `order_lookup` workload with up to 100 concurrent worker connections, a 25-second per-session delay, and a 30-minute runtime limit. |
| `profiles/high-connections-readonly-status-summary-profile.json` | Read-only `status_summary` workload with 25 threads, no added delay, and a 10-minute runtime limit. |

The two `high-connections-readonly` profiles do not insert or update data. The first is designed to keep many connections active; run it only against an environment where that connection load is acceptable.

## What It Exercises

The workload uses existing Bluebox routines already in this project:

- Insert order simulation: `CALL bluebox.generate_rentals(...)`
- Update order simulation: `CALL bluebox.complete_rentals(...)`
- Report simulation: read from existing report functions like:
  - `bluebox.get_inventory_balance_report()`
  - `bluebox.get_customer_status_summary()`
  - `bluebox.get_overdue_rentals(...)`
  - `bluebox.get_film_availability(...)`

## Key Behaviors

- Multithreaded execution with configurable `threads`
- Configurable number of total workload `sessions`
- App-side per-transaction delay in milliseconds (`delay_ms`) after DB connection is established
- Optional stop limits:
  - `max_runtime_minutes` to stop submitting new transactions after X minutes
  - `max_transactions` to stop after X executed transactions
- Deadlock mode support:
  - operation weight `force_deadlock` can be used to intentionally create deadlocks
  - `deadlock.interval_seconds` controls how frequently each deadlock attempt runs
  - `deadlock.lock_timeout_seconds` sets lock timeout for deadlock attempts
- Idle-in-transaction mode support:
  - operation weight `idle_in_transaction` opens a real transaction, calls `generate_rentals`, sleeps for a configurable duration (holding the open transaction), runs a report, then commits
  - `idle_in_transaction.idle_seconds` controls how long the transaction sits idle
  - `idle_in_transaction.report_name` selects the report run after the sleep (same values as `report.report_name`)
  - `insert_order.window_minutes` is reused to size the `generate_rentals` call window
- Service/application name comes from profile `service_name` and is sent to Postgres as `application_name`
- Connection target is profile-driven (`host`, `port`, `dbname`, `user`, `password`)

## Profile Format

```json
{
  "service_name": "Order-service-large-profile",
  "db": {
    "host": "${BLUEBOX_DB_HOST:-host.docker.internal}",
    "port": "${BLUEBOX_DB_PORT:-5432}",
    "dbname": "${BLUEBOX_DB_NAME:-bluebox}",
    "user": "${BLUEBOX_DB_USER:-bb_app}",
    "password": "${BLUEBOX_DB_PASSWORD}",
    "sslmode": "${BLUEBOX_DB_SSLMODE:-prefer}",
    "connect_timeout": "${BLUEBOX_DB_CONNECT_TIMEOUT:-10}"
  },
  "workload": {
    "sessions": 400,
    "threads": 24,
    "delay_ms": 25,
    "max_runtime_minutes": 30,
    "max_transactions": 1000
  },
  "operation_weights": {
    "insert_order": 60,
    "update_order": 30,
    "run_report": 10,
    "force_deadlock": 0,
    "idle_in_transaction": 0
  },
  "idle_in_transaction": {
    "idle_seconds": 30,
    "report_name": "status_summary"
  },
  "deadlock": {
    "interval_seconds": 10,
    "lock_timeout_seconds": 5
  },
  "insert_order": {
    "window_minutes": 5
  },
  "update_order": {
    "min_rental_age_hours": 16,
    "completion_pct": 25.0
  },
  "report": {
    "report_name": "inventory_balance",
    "overdue_days": 7,
    "film_min_stores": 0
  }
}
```

## Run Locally

From this directory:

```bash
chmod +x run-local.sh
./run-local.sh profiles/order-service-large-profile.json
./run-local.sh profiles/shipping-service-small-profile.json
./run-local.sh profiles/ec2-order-service-sustained-profile.json
./run-local.sh profiles/deadlock-service-profile.json
./run-local.sh profiles/idle-in-transaction-profile.json
./run-local.sh profiles/idle-in-transaction-profile_new.json
./run-local.sh profiles/high-connections-readonly-profile.json
./run-local.sh profiles/high-connections-readonly-status-summary-profile.json
```

After installing the requirements, run the status-summary read-only workload with JSON output:

```bash
python3 -m bluebox_loader.main --profile profiles/high-connections-readonly-status-summary-profile.json --output-json
```

The local wrapper accepts the profile path as its first argument. Use the module directly when you need loader options such as `--output-json`.

Or run directly:

```bash
python3 -m pip install -r requirements.txt
python3 -m bluebox_loader.main --profile profiles/order-service-large-profile.json --output-json
```

## Run in Docker

Build image:

```bash
docker build -t bluebox-loader:latest .
```

Run with default profile in image:

```bash
docker run --rm bluebox-loader:latest
```

Run with profile + env parity script (recommended):

```bash
chmod +x run-docker.sh
export BLUEBOX_DB_PASSWORD='app_password'
./run-docker.sh profiles/ec2-order-service-sustained-profile.json
```

Run deadlock profile (forces deadlocks at configured interval):

```bash
./run-docker.sh profiles/deadlock-service-profile.json --output-json
```

Run idle-in-transaction profile (holds an open transaction idle for `idle_seconds`):

```bash
./run-docker.sh profiles/idle-in-transaction-profile.json --output-json
```

Run the higher-throughput idle-in-transaction variant:

```bash
./run-docker.sh profiles/idle-in-transaction-profile_new.json --output-json
```

Run either read-only profile:

```bash
./run-docker.sh profiles/high-connections-readonly-profile.json --output-json
./run-docker.sh profiles/high-connections-readonly-status-summary-profile.json --output-json
```

The first read-only profile can hold up to 100 worker connections and waits 25 seconds after connecting before its report query. Use it to test connection pressure only on a database where that load is acceptable. The status-summary variant starts report queries without that added delay and uses at most 25 worker threads.

Optional JSON output:

```bash
./run-docker.sh profiles/ec2-order-service-sustained-profile.json --output-json
```

Health-check only (2 lightweight transactions by default):

```bash
./run-docker.sh profiles/ec2-order-service-sustained-profile.json --health-check-only --output-json
```

Run health-check before workload:

```bash
./run-docker.sh profiles/ec2-order-service-sustained-profile.json --health-check-transactions 2 --output-json
```

The script passes these variables into the container for local and EC2 parity:

- `BLUEBOX_DB_HOST`
- `BLUEBOX_DB_PORT`
- `BLUEBOX_DB_NAME`
- `BLUEBOX_DB_USER`
- `BLUEBOX_DB_PASSWORD` (required)
- `BLUEBOX_DB_SSLMODE`
- `BLUEBOX_DB_CONNECT_TIMEOUT`

You can also still run Docker directly if preferred:

```bash
docker run --rm \
  -v "$PWD/profiles:/app/profiles" \
  -e BLUEBOX_DB_PASSWORD='app_password' \
  bluebox-loader:latest \
  --profile profiles/shipping-service-small-profile.json
```

## Deploy on AWS EC2

1. Copy project to `/opt/bluebox-loader`.
2. Install dependencies and systemd service:

```bash
chmod +x deploy/ec2/install-ec2.sh
./deploy/ec2/install-ec2.sh
```

3. Change profile used by the service:

```bash
sudo sed -i 's#PROFILE_FILE=.*#PROFILE_FILE=profiles/shipping-service-small-profile.json#' /etc/systemd/system/bluebox-loader.service
sudo systemctl daemon-reload
sudo systemctl restart bluebox-loader
```

4. Check service logs:

```bash
sudo journalctl -u bluebox-loader -f
```

## Environment Variable Substitution

Profile string values can reference environment variables:

- `${VAR_NAME}`: required environment variable
- `${VAR_NAME:-default}`: optional with default fallback

Example DB section:

```json
{
  "db": {
    "host": "${BLUEBOX_DB_HOST:-host.docker.internal}",
    "port": "${BLUEBOX_DB_PORT:-5432}",
    "dbname": "${BLUEBOX_DB_NAME:-bluebox}",
    "user": "${BLUEBOX_DB_USER:-bb_app}",
    "password": "${BLUEBOX_DB_PASSWORD}"
  }
}
```

Example run:

```bash
export BLUEBOX_DB_PASSWORD='app_password'
./run-local.sh profiles/ec2-order-service-sustained-profile.json
```

Run local health-check only:

```bash
python3 -m bluebox_loader.main \
  --profile profiles/ec2-order-service-sustained-profile.json \
  --health-check-only \
  --output-json
```

## Notes

- Ensure Bluebox DB is reachable from where the loader runs.
- Use different profile files for each app/team/load scenario.
- Keep credentials in environment-specific secure storage for production usage.
