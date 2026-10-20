from __future__ import annotations

import statistics
import threading
import time
from collections import Counter
from concurrent.futures import FIRST_COMPLETED, ThreadPoolExecutor, wait
from dataclasses import dataclass
from typing import Any

from .config import Profile
from .db import build_dsn, pick_operation, run_operation


@dataclass
class WorkloadSummary:
    service_name: str
    configured_sessions: int
    sessions: int
    threads: int
    successes: int
    failures: int
    by_operation: dict[str, int]
    avg_latency_ms: float
    p95_latency_ms: float
    max_runtime_minutes: float | None
    max_transactions: int | None
    stop_reason: str
    errors: list[str]
    total_queries: int = 0


def _percentile(values: list[float], percentile: float) -> float:
    if not values:
        return 0.0
    if len(values) == 1:
        return values[0]

    sorted_values = sorted(values)
    rank = percentile * (len(sorted_values) - 1)
    low = int(rank)
    high = min(low + 1, len(sorted_values) - 1)
    weight = rank - low
    return sorted_values[low] * (1 - weight) + sorted_values[high] * weight


def execute_workload(profile: Profile, verbose: bool = False) -> WorkloadSummary:
    dsn = build_dsn(profile)
    latencies: list[float] = []
    by_operation: Counter[str] = Counter()
    failures: list[str] = []
    completed_transactions = 0
    total_queries = 0

    lock = threading.Lock()
    started_at = time.monotonic()

    target_transactions = profile.workload.sessions
    if profile.workload.max_transactions is not None:
        target_transactions = min(target_transactions, profile.workload.max_transactions)

    runtime_limit_seconds: float | None = None
    if profile.workload.max_runtime_minutes is not None:
        runtime_limit_seconds = profile.workload.max_runtime_minutes * 60.0

    stop_reason = "completed configured target"

    def _run_session(_session_idx: int) -> dict[str, Any]:
        op = pick_operation(profile)
        result = run_operation(profile, dsn, op)
        return {
            "operation": result.operation,
            "success": result.success,
            "elapsed_ms": result.elapsed_ms,
            "error": result.error,
            "queries": result.queries,
        }

    def _time_remaining() -> bool:
        if runtime_limit_seconds is None:
            return True
        return (time.monotonic() - started_at) < runtime_limit_seconds

    with ThreadPoolExecutor(max_workers=profile.workload.threads) as executor:
        in_flight = set()
        submitted_transactions = 0

        while submitted_transactions < target_transactions and _time_remaining() and len(in_flight) < profile.workload.threads:
            in_flight.add(executor.submit(_run_session, submitted_transactions))
            submitted_transactions += 1

        while in_flight:
            done, pending = wait(in_flight, timeout=0.25, return_when=FIRST_COMPLETED)
            if not done:
                in_flight = pending
                if runtime_limit_seconds is not None and not _time_remaining() and submitted_transactions < target_transactions:
                    stop_reason = "stopped by max_runtime_minutes"
                continue

            in_flight = set(pending)
            for future in done:
                session_result = future.result()
                with lock:
                    completed_transactions += 1
                    by_operation[session_result["operation"]] += 1
                    latencies.append(session_result["elapsed_ms"])
                    total_queries += session_result.get("queries", 0)
                    if not session_result["success"] and session_result["error"]:
                        failures.append(session_result["error"])
                    if verbose:
                        elapsed_s = time.monotonic() - started_at
                        status = "OK" if session_result["success"] else "FAIL"
                        print(
                            f"[verbose] [{elapsed_s:6.1f}s] "
                            f"txn={completed_transactions}/{target_transactions}  "
                            f"op={session_result['operation']:<20}  "
                            f"{session_result['elapsed_ms']:7.1f}ms  "
                            f"{status}",
                            flush=True,
                        )

            while submitted_transactions < target_transactions and _time_remaining() and len(in_flight) < profile.workload.threads:
                in_flight.add(executor.submit(_run_session, submitted_transactions))
                submitted_transactions += 1

            if runtime_limit_seconds is not None and not _time_remaining() and submitted_transactions < target_transactions:
                stop_reason = "stopped by max_runtime_minutes"

    if completed_transactions >= target_transactions:
        if profile.workload.max_transactions is not None and target_transactions == profile.workload.max_transactions:
            stop_reason = "stopped by max_transactions"
        else:
            stop_reason = "completed configured target"

    total_failures = len(failures)
    total_successes = completed_transactions - total_failures

    return WorkloadSummary(
        service_name=profile.service_name,
        configured_sessions=profile.workload.sessions,
        sessions=completed_transactions,
        threads=profile.workload.threads,
        successes=total_successes,
        failures=total_failures,
        by_operation=dict(by_operation),
        total_queries=total_queries,
        avg_latency_ms=statistics.fmean(latencies) if latencies else 0.0,
        p95_latency_ms=_percentile(latencies, 0.95),
        max_runtime_minutes=profile.workload.max_runtime_minutes,
        max_transactions=profile.workload.max_transactions,
        stop_reason=stop_reason,
        errors=failures[:20],
    )
