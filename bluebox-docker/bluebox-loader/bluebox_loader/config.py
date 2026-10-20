from __future__ import annotations

import json
import os
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any


ENV_PATTERN = re.compile(r"^\$\{([A-Za-z_][A-Za-z0-9_]*)(?::-(.*))?\}$")


@dataclass(frozen=True)
class DbConfig:
    host: str
    port: int
    dbname: str
    user: str
    password: str
    sslmode: str = "prefer"
    connect_timeout: int = 10


@dataclass(frozen=True)
class WorkloadConfig:
    sessions: int
    threads: int
    delay_ms: int
    max_runtime_minutes: float | None = None
    max_transactions: int | None = None


@dataclass(frozen=True)
class OperationWeights:
    insert_order: int
    update_order: int
    run_report: int
    force_deadlock: int
    idle_in_transaction: int = 0


@dataclass(frozen=True)
class InsertOrderConfig:
    window_minutes: int = 5


@dataclass(frozen=True)
class UpdateOrderConfig:
    min_rental_age_hours: int = 16
    completion_pct: float = 15.0


@dataclass(frozen=True)
class ReportConfig:
    report_name: str = "inventory_balance"
    overdue_days: int = 7
    film_min_stores: int = 0


@dataclass(frozen=True)
class DeadlockConfig:
    interval_seconds: float = 5.0
    lock_timeout_seconds: int = 15


@dataclass(frozen=True)
class IdleInTransactionConfig:
    idle_seconds: float = 30.0
    report_name: str = "status_summary"


@dataclass(frozen=True)
class Profile:
    service_name: str
    db: DbConfig
    workload: WorkloadConfig
    operation_weights: OperationWeights
    insert_order: InsertOrderConfig
    update_order: UpdateOrderConfig
    report: ReportConfig
    deadlock: DeadlockConfig
    idle_in_transaction: IdleInTransactionConfig = IdleInTransactionConfig()


def _require(data: dict[str, Any], key: str) -> Any:
    if key not in data:
        raise ValueError(f"Missing required profile key: {key}")
    return data[key]


def _resolve_env_value(value: Any) -> Any:
    if isinstance(value, dict):
        return {k: _resolve_env_value(v) for k, v in value.items()}
    if isinstance(value, list):
        return [_resolve_env_value(v) for v in value]
    if not isinstance(value, str):
        return value

    match = ENV_PATTERN.match(value.strip())
    if not match:
        return value

    env_name = match.group(1)
    default_value = match.group(2)
    env_value = os.getenv(env_name)

    if env_value is not None:
        return env_value
    if default_value is not None:
        return default_value

    raise ValueError(
        f"Environment variable '{env_name}' is not set and no default was provided"
    )


def _build_db_config(raw: dict[str, Any]) -> DbConfig:
    return DbConfig(
        host=str(_require(raw, "host")),
        port=int(_require(raw, "port")),
        dbname=str(_require(raw, "dbname")),
        user=str(_require(raw, "user")),
        password=str(_require(raw, "password")),
        sslmode=str(raw.get("sslmode", "prefer")),
        connect_timeout=int(raw.get("connect_timeout", 10)),
    )


def _build_workload_config(raw: dict[str, Any]) -> WorkloadConfig:
    sessions = int(_require(raw, "sessions"))
    threads = int(_require(raw, "threads"))
    delay_ms = int(raw.get("delay_ms", 0))
    max_runtime_minutes_raw = raw.get("max_runtime_minutes")
    max_transactions_raw = raw.get("max_transactions")

    if sessions <= 0:
        raise ValueError("workload.sessions must be > 0")
    if threads <= 0:
        raise ValueError("workload.threads must be > 0")
    if delay_ms < 0:
        raise ValueError("workload.delay_ms must be >= 0")

    max_runtime_minutes: float | None = None
    if max_runtime_minutes_raw is not None:
        max_runtime_minutes = float(max_runtime_minutes_raw)
        if max_runtime_minutes <= 0:
            raise ValueError("workload.max_runtime_minutes must be > 0 when set")

    max_transactions: int | None = None
    if max_transactions_raw is not None:
        max_transactions = int(max_transactions_raw)
        if max_transactions <= 0:
            raise ValueError("workload.max_transactions must be > 0 when set")

    return WorkloadConfig(
        sessions=sessions,
        threads=threads,
        delay_ms=delay_ms,
        max_runtime_minutes=max_runtime_minutes,
        max_transactions=max_transactions,
    )


def _build_weights(raw: dict[str, Any]) -> OperationWeights:
    weights = OperationWeights(
        insert_order=int(raw.get("insert_order", 1)),
        update_order=int(raw.get("update_order", 1)),
        run_report=int(raw.get("run_report", 1)),
        force_deadlock=int(raw.get("force_deadlock", 0)),
        idle_in_transaction=int(raw.get("idle_in_transaction", 0)),
    )
    if (
        weights.insert_order < 0
        or weights.update_order < 0
        or weights.run_report < 0
        or weights.force_deadlock < 0
        or weights.idle_in_transaction < 0
    ):
        raise ValueError("operation_weights cannot contain negative values")
    if (
        weights.insert_order
        + weights.update_order
        + weights.run_report
        + weights.force_deadlock
        + weights.idle_in_transaction
        == 0
    ):
        raise ValueError("operation_weights total must be > 0")
    return weights


def load_profile(profile_path: str | Path) -> Profile:
    path = Path(profile_path)
    if not path.exists():
        raise FileNotFoundError(f"Profile not found: {path}")

    with path.open("r", encoding="utf-8") as f:
        raw = _resolve_env_value(json.load(f))

    service_name = str(_require(raw, "service_name")).strip()
    if not service_name:
        raise ValueError("service_name cannot be empty")

    db = _build_db_config(_require(raw, "db"))
    workload = _build_workload_config(_require(raw, "workload"))
    weights = _build_weights(raw.get("operation_weights", {}))

    insert_order_raw = raw.get("insert_order", {})
    update_order_raw = raw.get("update_order", {})
    report_raw = raw.get("report", {})
    deadlock_raw = raw.get("deadlock", {})
    idle_in_transaction_raw = raw.get("idle_in_transaction", {})

    insert_order = InsertOrderConfig(
        window_minutes=int(insert_order_raw.get("window_minutes", 5))
    )
    update_order = UpdateOrderConfig(
        min_rental_age_hours=int(update_order_raw.get("min_rental_age_hours", 16)),
        completion_pct=float(update_order_raw.get("completion_pct", 15.0)),
    )
    report = ReportConfig(
        report_name=str(report_raw.get("report_name", "inventory_balance")),
        overdue_days=int(report_raw.get("overdue_days", 7)),
        film_min_stores=int(report_raw.get("film_min_stores", 0)),
    )
    deadlock = DeadlockConfig(
        interval_seconds=float(deadlock_raw.get("interval_seconds", 5.0)),
        lock_timeout_seconds=int(deadlock_raw.get("lock_timeout_seconds", 5)),
    )
    idle_in_transaction = IdleInTransactionConfig(
        idle_seconds=float(idle_in_transaction_raw.get("idle_seconds", 30.0)),
        report_name=str(idle_in_transaction_raw.get("report_name", "status_summary")),
    )

    if insert_order.window_minutes <= 0:
        raise ValueError("insert_order.window_minutes must be > 0")
    if update_order.min_rental_age_hours <= 0:
        raise ValueError("update_order.min_rental_age_hours must be > 0")
    if not (0 <= update_order.completion_pct <= 100):
        raise ValueError("update_order.completion_pct must be between 0 and 100")
    if deadlock.interval_seconds <= 0:
        raise ValueError("deadlock.interval_seconds must be > 0")
    if deadlock.lock_timeout_seconds <= 0:
        raise ValueError("deadlock.lock_timeout_seconds must be > 0")
    if idle_in_transaction.idle_seconds < 0:
        raise ValueError("idle_in_transaction.idle_seconds must be >= 0")

    return Profile(
        service_name=service_name,
        db=db,
        workload=workload,
        operation_weights=weights,
        insert_order=insert_order,
        update_order=update_order,
        report=report,
        deadlock=deadlock,
        idle_in_transaction=idle_in_transaction,
    )
