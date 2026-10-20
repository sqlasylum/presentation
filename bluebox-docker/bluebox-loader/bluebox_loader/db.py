from __future__ import annotations

import random
import threading
import time
from datetime import datetime, timezone
from dataclasses import dataclass
from typing import Literal

import psycopg

from .config import Profile

OperationName = Literal["insert_order", "update_order", "run_report", "force_deadlock", "idle_in_transaction"]


# Number of SQL statements issued per operation on success.
# idle_in_transaction: generate_rentals + SELECT 1 + report = 3
# force_deadlock:      SELECT pair + 4 UPDATEs across two threads = 5
# all others:          single CALL or SELECT = 1
QUERIES_PER_OPERATION: dict[str, int] = {
    "insert_order":        1,
    "update_order":        1,
    "run_report":          1,
    "idle_in_transaction": 3,
    "force_deadlock":      5,
}


@dataclass
class OperationResult:
    operation: OperationName
    success: bool
    elapsed_ms: float
    error: str | None = None
    queries: int = 0


@dataclass
class HealthCheckResult:
    requested_transactions: int
    successes: int
    failures: int
    elapsed_ms: float
    errors: list[str]


REPORT_SQL: dict[str, str] = {
    "inventory_balance": "SELECT count(*) FROM bluebox.get_inventory_balance_report();",
    "status_summary": "SELECT count(*) FROM bluebox.get_customer_status_summary();",
    "overdue_rentals": "SELECT count(*) FROM bluebox.get_overdue_rentals(%s);",
    "film_availability": "SELECT count(*) FROM bluebox.get_film_availability(%s);",
    "order_lookup": "SELECT rental_id FROM bluebox.rental ORDER BY rental_id DESC LIMIT 1;",
}


def build_dsn(profile: Profile) -> str:
    db = profile.db
    # service_name is propagated to Postgres application_name for tracing by workload profile.
    return (
        f"host={db.host} "
        f"port={db.port} "
        f"dbname={db.dbname} "
        f"user={db.user} "
        f"password={db.password} "
        f"sslmode={db.sslmode} "
        f"connect_timeout={db.connect_timeout} "
        f"application_name={profile.service_name}"
    )


def pick_operation(profile: Profile) -> OperationName:
    weights = profile.operation_weights
    operations = ["insert_order", "update_order", "run_report", "force_deadlock", "idle_in_transaction"]
    selected = random.choices(
        operations,
        weights=[
            weights.insert_order,
            weights.update_order,
            weights.run_report,
            weights.force_deadlock,
            weights.idle_in_transaction,
        ],
        k=1,
    )[0]
    return selected  # type: ignore[return-value]


def _select_deadlock_pair(dsn: str) -> tuple[int, int]:
    with psycopg.connect(dsn, autocommit=True) as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT i.inventory_id
                FROM bluebox.inventory i
                ORDER BY i.inventory_id
                LIMIT 2
                """
            )
            rows = cur.fetchall()

    if len(rows) < 2:
        raise RuntimeError("Need at least 2 rows in bluebox.inventory to force deadlock")

    return int(rows[0][0]), int(rows[1][0])


def _force_deadlock(profile: Profile, dsn: str) -> None:
    first_id, second_id = _select_deadlock_pair(dsn)

    conn_a = psycopg.connect(dsn, autocommit=False)
    conn_b = psycopg.connect(dsn, autocommit=False)
    conn_a.execute(f"SET lock_timeout = '{profile.deadlock.lock_timeout_seconds}s';")
    conn_b.execute(f"SET lock_timeout = '{profile.deadlock.lock_timeout_seconds}s';")

    barrier = threading.Barrier(2)
    errors: list[Exception] = []
    deadlock_seen = False

    def _txn_a() -> None:
        nonlocal deadlock_seen
        try:
            with conn_a.cursor() as cur:
                cur.execute("UPDATE bluebox.inventory SET last_update = now() WHERE inventory_id = %s", (first_id,))
                barrier.wait(timeout=10)
                cur.execute("UPDATE bluebox.inventory SET last_update = now() WHERE inventory_id = %s", (second_id,))
            conn_a.commit()
        except Exception as exc:  # noqa: BLE001
            conn_a.rollback()
            if isinstance(exc, psycopg.Error) and exc.sqlstate == "40P01":
                deadlock_seen = True
            else:
                errors.append(exc)

    def _txn_b() -> None:
        nonlocal deadlock_seen
        try:
            with conn_b.cursor() as cur:
                cur.execute("UPDATE bluebox.inventory SET last_update = now() WHERE inventory_id = %s", (second_id,))
                barrier.wait(timeout=10)
                cur.execute("UPDATE bluebox.inventory SET last_update = now() WHERE inventory_id = %s", (first_id,))
            conn_b.commit()
        except Exception as exc:  # noqa: BLE001
            conn_b.rollback()
            if isinstance(exc, psycopg.Error) and exc.sqlstate == "40P01":
                deadlock_seen = True
            else:
                errors.append(exc)

    try:
        thread_a = threading.Thread(target=_txn_a)
        thread_b = threading.Thread(target=_txn_b)
        thread_a.start()
        thread_b.start()
        thread_a.join()
        thread_b.join()
    finally:
        conn_a.close()
        conn_b.close()

    if errors:
        raise RuntimeError(str(errors[0]))
    if not deadlock_seen:
        raise RuntimeError("Deadlock was not observed for this attempt")

    # Emit immediate feedback so users can see deadlocks in live script output.
    ts = datetime.now(timezone.utc).isoformat(timespec="seconds")
    print(
        f"[deadlock] detected at {ts} between inventory_id {first_id} and {second_id}",
        flush=True,
    )


def _run_idle_in_transaction(profile: Profile, dsn: str) -> int:
    """Call generate_rentals, then hold an explicit transaction open (idle in transaction)
    for idle_seconds before running a report and committing.

    generate_rentals issues its own COMMIT internally and must run outside an explicit
    transaction block (autocommit=True). A second connection then opens an explicit
    transaction, sleeps idle_seconds so the session appears as 'idle in transaction'
    in pg_stat_activity, runs the report, and commits.
    """
    cfg = profile.idle_in_transaction
    sql = REPORT_SQL.get(cfg.report_name)
    query_attempts = 0
    if sql is None:
        raise ValueError(
            f"Unsupported idle_in_transaction.report_name '{cfg.report_name}'. "
            f"Supported: {', '.join(sorted(REPORT_SQL.keys()))}"
        )

    # Phase 1: generate_rentals manages its own transactions internally, so it
    # must run at the top level with autocommit=True.
    with psycopg.connect(dsn, autocommit=True) as conn:
        with conn.cursor() as cur:
            query_attempts += 1
            cur.execute(
                """
                CALL bluebox.generate_rentals(
                    p_start_time := now() - make_interval(mins => %s),
                    p_end_time := now(),
                    p_close_rentals := false,
                    p_print_debug := false
                )
                """,
                (profile.insert_order.window_minutes,),
            )

    # Phase 2: open an explicit transaction, execute a lightweight query to enter
    # the transaction block, then sleep so the connection sits as
    # 'idle in transaction' in pg_stat_activity for idle_seconds.
    with psycopg.connect(dsn, autocommit=False) as conn:
        with conn.cursor() as cur:
            query_attempts += 1
            cur.execute("SELECT 1")
            cur.fetchone()

            # Client-side sleep: the server sees this connection as idle in transaction.
            time.sleep(cfg.idle_seconds)

            if cfg.report_name == "overdue_rentals":
                query_attempts += 1
                cur.execute(sql, (profile.report.overdue_days,))
            elif cfg.report_name == "film_availability":
                query_attempts += 1
                cur.execute(sql, (profile.report.film_min_stores,))
            else:
                query_attempts += 1
                cur.execute(sql)
            cur.fetchone()
        conn.commit()

    return query_attempts


def run_operation(profile: Profile, dsn: str, op: OperationName) -> OperationResult:
    started = time.perf_counter()
    delay_seconds = profile.workload.delay_ms / 1000.0
    query_attempts = 0

    try:
        if op == "force_deadlock":
            _force_deadlock(profile, dsn)
            time.sleep(profile.deadlock.interval_seconds)
            elapsed = (time.perf_counter() - started) * 1000
            return OperationResult(operation=op, success=True, elapsed_ms=elapsed, queries=QUERIES_PER_OPERATION[op])

        if op == "idle_in_transaction":
            query_attempts = _run_idle_in_transaction(profile, dsn)
            elapsed = (time.perf_counter() - started) * 1000
            return OperationResult(operation=op, success=True, elapsed_ms=elapsed, queries=query_attempts)

        with psycopg.connect(dsn, autocommit=True) as conn:
            # Delay happens application-side after DB connect, as requested.
            if delay_seconds > 0:
                time.sleep(delay_seconds)

            with conn.cursor() as cur:
                if op == "insert_order":
                    query_attempts += 1
                    cur.execute(
                        """
                        CALL bluebox.generate_rentals(
                            p_start_time := now() - make_interval(mins => %s),
                            p_end_time := now(),
                            p_close_rentals := false,
                            p_print_debug := false
                        )
                        """,
                        (profile.insert_order.window_minutes,),
                    )
                elif op == "update_order":
                    query_attempts += 1
                    cur.execute(
                        """
                        CALL bluebox.complete_rentals(
                            p_min_rental_age := make_interval(hours => %s),
                            p_completion_pct := (%s)::numeric,
                            p_print_debug := false
                        )
                        """,
                        (
                            profile.update_order.min_rental_age_hours,
                            profile.update_order.completion_pct,
                        ),
                    )
                elif op == "run_report":
                    report_name = profile.report.report_name
                    sql = REPORT_SQL.get(report_name)
                    if sql is None:
                        raise ValueError(
                            f"Unsupported report.report_name '{report_name}'. "
                            f"Supported: {', '.join(sorted(REPORT_SQL.keys()))}"
                        )

                    if report_name == "overdue_rentals":
                        query_attempts += 1
                        cur.execute(sql, (profile.report.overdue_days,))
                    elif report_name == "film_availability":
                        query_attempts += 1
                        cur.execute(sql, (profile.report.film_min_stores,))
                    else:
                        query_attempts += 1
                        cur.execute(sql)
                    cur.fetchone()
                else:
                    raise ValueError(f"Unsupported operation: {op}")

        elapsed = (time.perf_counter() - started) * 1000
        if query_attempts == 0:
            query_attempts = QUERIES_PER_OPERATION.get(op, 1)
        return OperationResult(operation=op, success=True, elapsed_ms=elapsed, queries=query_attempts)
    except Exception as exc:  # noqa: BLE001
        elapsed = (time.perf_counter() - started) * 1000
        return OperationResult(operation=op, success=False, elapsed_ms=elapsed, error=str(exc), queries=query_attempts)


def run_health_check(profile: Profile, dsn: str, transactions: int = 2) -> HealthCheckResult:
    if transactions <= 0:
        raise ValueError("transactions must be > 0")

    started = time.perf_counter()
    successes = 0
    errors: list[str] = []

    report_name = profile.report.report_name
    sql = REPORT_SQL.get(report_name)
    if sql is None:
        raise ValueError(
            f"Unsupported report.report_name '{report_name}'. "
            f"Supported: {', '.join(sorted(REPORT_SQL.keys()))}"
        )

    for _ in range(transactions):
        try:
            with psycopg.connect(dsn, autocommit=True) as conn:
                with conn.cursor() as cur:
                    cur.execute("SELECT 1;")
                    cur.fetchone()

                    if report_name == "overdue_rentals":
                        cur.execute(sql, (profile.report.overdue_days,))
                    elif report_name == "film_availability":
                        cur.execute(sql, (profile.report.film_min_stores,))
                    else:
                        cur.execute(sql)
                    cur.fetchone()
            successes += 1
        except Exception as exc:  # noqa: BLE001
            errors.append(str(exc))

    elapsed_ms = (time.perf_counter() - started) * 1000
    return HealthCheckResult(
        requested_transactions=transactions,
        successes=successes,
        failures=len(errors),
        elapsed_ms=elapsed_ms,
        errors=errors[:20],
    )
