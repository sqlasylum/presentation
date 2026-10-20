from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from .config import load_profile
from .db import build_dsn, run_health_check
from .runner import execute_workload


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Bluebox profile-driven load runner. "
            "Runs insert/update/report operations with multithreaded sessions."
        )
    )
    parser.add_argument(
        "--profile",
        required=True,
        help="Path to JSON profile file",
    )
    parser.add_argument(
        "--output-json",
        action="store_true",
        help="Print summary as JSON instead of plain text",
    )
    parser.add_argument(
        "--health-check-transactions",
        type=int,
        default=0,
        help="Run this many lightweight preflight transactions before workload (0 disables)",
    )
    parser.add_argument(
        "--health-check-only",
        action="store_true",
        help="Run only health-check transactions and exit",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Print progress after every transaction (operation, latency, running totals)",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    if args.health_check_transactions < 0:
        print("--health-check-transactions must be >= 0", file=sys.stderr)
        return 1

    preflight_transactions = args.health_check_transactions
    if args.health_check_only and preflight_transactions == 0:
        preflight_transactions = 2

    try:
        profile = load_profile(Path(args.profile))
        dsn = build_dsn(profile)

        healthcheck_result = None
        if preflight_transactions > 0 or args.health_check_only:
            healthcheck_result = run_health_check(
                profile,
                dsn,
                transactions=preflight_transactions if preflight_transactions > 0 else 2,
            )

            if healthcheck_result.failures > 0:
                print(
                    (
                        "Health check failed: "
                        f"{healthcheck_result.failures}/{healthcheck_result.requested_transactions} "
                        "transactions failed"
                    ),
                    file=sys.stderr,
                )
                for err in healthcheck_result.errors:
                    print(f"  - {err}", file=sys.stderr)
                return 1

            if args.health_check_only:
                payload = {
                    "service_name": profile.service_name,
                    "health_check": {
                        "requested_transactions": healthcheck_result.requested_transactions,
                        "successes": healthcheck_result.successes,
                        "failures": healthcheck_result.failures,
                        "elapsed_ms": round(healthcheck_result.elapsed_ms, 2),
                        "errors": healthcheck_result.errors,
                    },
                }
                if args.output_json:
                    print(json.dumps(payload, indent=2))
                else:
                    print(f"Service profile: {profile.service_name}")
                    print(
                        "Health check passed: "
                        f"{healthcheck_result.successes}/{healthcheck_result.requested_transactions}"
                    )
                    print(f"Elapsed: {healthcheck_result.elapsed_ms:.2f} ms")
                return 0

        if args.verbose:
            print(f"[verbose] Profile:  {profile.service_name}")
            print(f"[verbose] Target:   {profile.workload.sessions} sessions, {profile.workload.threads} threads")
            if profile.workload.max_runtime_minutes:
                print(f"[verbose] Limit:    {profile.workload.max_runtime_minutes} min runtime")
            if profile.workload.max_transactions:
                print(f"[verbose] Limit:    {profile.workload.max_transactions} max transactions")
            print(f"[verbose] Host:     {profile.db.host}:{profile.db.port}/{profile.db.dbname}")
            print("[verbose] Starting workload...", flush=True)
        summary = execute_workload(profile, verbose=args.verbose)
    except Exception as exc:  # noqa: BLE001
        print(f"Loader failed: {exc}", file=sys.stderr)
        return 1

    result = {
        "service_name": summary.service_name,
        "configured_sessions": summary.configured_sessions,
        "sessions": summary.sessions,
        "threads": summary.threads,
        "max_runtime_minutes": summary.max_runtime_minutes,
        "max_transactions": summary.max_transactions,
        "stop_reason": summary.stop_reason,
        "successes": summary.successes,
        "failures": summary.failures,
        "total_queries": summary.total_queries,
        "by_operation": summary.by_operation,
        "avg_latency_ms": round(summary.avg_latency_ms, 2),
        "p95_latency_ms": round(summary.p95_latency_ms, 2),
        "errors": summary.errors,
    }

    if args.output_json:
        print(json.dumps(result, indent=2))
    else:
        print(f"Service profile: {summary.service_name}")
        print(
            f"Sessions executed: {summary.sessions} "
            f"(configured: {summary.configured_sessions})  Threads: {summary.threads}"
        )
        print(
            f"Limits -> max_runtime_minutes: {summary.max_runtime_minutes}, "
            f"max_transactions: {summary.max_transactions}"
        )
        print(f"Stop reason: {summary.stop_reason}")
        print(f"Successes: {summary.successes}  Failures: {summary.failures}")
        print(f"Total queries executed: {summary.total_queries}")
        print(f"Operation counts: {summary.by_operation}")
        print(f"Average latency: {summary.avg_latency_ms:.2f} ms")
        print(f"P95 latency: {summary.p95_latency_ms:.2f} ms")
        if summary.errors:
            print("Sample errors:")
            for err in summary.errors:
                print(f"  - {err}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
