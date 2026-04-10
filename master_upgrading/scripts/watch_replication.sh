#!/bin/bash
# ══════════════════════════════════════════════════════
#  watch_replication.sh  —  Live replication lag monitor.
#  Run on the PRIMARY.
# ══════════════════════════════════════════════════════

PG_VERSION=${PG_VERSION:-15}
BIN=/usr/lib/postgresql/${PG_VERSION}/bin

watch -n 2 "
  echo '=== Replication Senders ($(date)) ==='
  sudo -u postgres $BIN/psql -U postgres -x -c \"
    SELECT
      client_addr,
      application_name,
      state,
      sync_state,
      sent_lsn,
      write_lsn,
      flush_lsn,
      replay_lsn,
      (sent_lsn - replay_lsn) AS lag_bytes,
      write_lag,
      flush_lag,
      replay_lag
    FROM pg_stat_replication;
  \"

  echo ''
  echo '=== Standby is receiving WAL from: ==='
  sudo -u postgres $BIN/psql -U postgres -t -c \"
    SELECT 'Primary LSN: ' || pg_current_wal_lsn();
  \"
"
