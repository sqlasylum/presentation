--replication slot status and lag
SELECT prs.slot_name, (''::text || round(pg_wal_lsn_diff(pg_current_wal_lsn(), prs.restart_lsn) / (1024 * 1024 * 1024)::numeric)) || ''::text AS "WAL on Master", 
prs.slot_type AS "Slot Type", 
CASE WHEN prs.active = true THEN 'TRUE'::text ELSE 'FALSE'::text END AS "Active", psr.state, 
(''::text || round(pg_wal_lsn_diff(pg_current_wal_lsn(), psr.replay_lsn) / (1024 * 1024 * 1024)::numeric)) || ''::text AS "WAL on Replica",
COALESCE(round(date_part('epoch'::text, psr.replay_lag) / 60::double precision), NULL::double precision, 0::double precision) AS log_delay, 
prs.database
FROM pg_replication_slots prs LEFT JOIN pg_stat_replication psr ON prs.active_pid = psr.pid 
ORDER BY prs.active, psr.application_name, psr.pid; 