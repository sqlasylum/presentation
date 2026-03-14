
--Check Activity 
SELECT pg_stat_activity.pid,datname,state,wait_event_type,
(now() - pg_stat_activity.xact_start) AS "Transaction duration",
(now() - pg_stat_activity.state_change) AS "Query state change",
(now() - pg_stat_activity.query_start) AS "Query age",
pg_stat_activity.usename,pg_stat_activity.application_name
FROM pg_stat_activity 
WHERE 
--((pg_stat_activity.state = ANY (ARRAY['active'::text, 'idle in transaction'::text, 'idle'::text, 'idle'::text])))  
-- AND   (((now() - pg_stat_activity.xact_start) > '00:00:15'::interval) 
-- OR    ((pg_stat_activity.backend_start - now()) > '00:00:15'::interval) 
-- OR    ((pg_stat_activity.query_start - now()) > '00:00:15'::interval))
--AND   
(pg_stat_activity.backend_type = ANY (ARRAY['client backend'::text])) 
AND   (pg_stat_activity.application_name <> ALL (ARRAY['vacuumdb'::text, 'pg_dump'::text])) 
--and state = 'active'
--and usename = 'specfic_user'
order by 5 desc,application_name, 3;

--check application count
select count(*),application_name,datname, usename,state 
from pg_stat_activity 
where (usename IS NOT NULL and datname IS NOT NULL and USENAME <> 'rdsadmin')
and state = 'active'
group by 2,3,4,5 
order by 5,1 desc, 1 desc;



--lead blocker query
select pid,
       usename,
       pg_blocking_pids(pid) as blocked_by,
       query as blocked_query
from pg_stat_activity
where cardinality(pg_blocking_pids(pid)) > 0;


--Showing locks and lead blockers together
WITH RECURSIVE 
l AS (
  SELECT pg_locks.pid, pg_locks.locktype, pg_locks.mode, pg_locks.granted,
  ROW(pg_locks.locktype, pg_locks.database, pg_locks.relation, pg_locks.page, pg_locks.tuple, pg_locks.virtualxid, pg_locks.transactionid, pg_locks.classid, pg_locks.objid, pg_locks.objsubid) AS obj
  FROM pg_locks), 
pairs AS (
  SELECT w.pid AS waiter, l.pid AS locker, l.obj, l.mode
  FROM l w JOIN l ON NOT l.obj IS DISTINCT FROM w.obj AND l.locktype = w.locktype AND NOT l.pid = w.pid AND l.granted
  WHERE NOT w.granted), 
tree AS ( 
  SELECT l.locker AS pid, l.locker AS root, NULL::record AS obj, NULL::text AS mode, 0 AS lvl, l.locker::text AS path, array_agg(l.locker) OVER () AS all_pids
  FROM ( SELECT DISTINCT l_1.locker
         FROM pairs l_1
         WHERE NOT (EXISTS ( SELECT 1
                             FROM pairs
                             WHERE pairs.waiter = l_1.locker))) l
  UNION ALL
  SELECT w.waiter AS pid, tree_1.root, w.obj, w.mode, tree_1.lvl + 1, (tree_1.path || '.'::text) || w.waiter, tree_1.all_pids || array_agg(w.waiter) OVER ()
  FROM tree tree_1 JOIN pairs w ON tree_1.pid = w.locker AND NOT (w.waiter = ANY (tree_1.all_pids)))
SELECT (clock_timestamp() - a.xact_start)::interval(3) AS transaction_age, a.application_name, a.wait_event_type, replace(a.state, 'idle in transaction'::text, 'idletx'::text) AS state,
       (clock_timestamp() - a.state_change)::interval(3) AS change_age, a.datname, tree.pid, a.usename, tree.lvl AS lock_level,
       ( SELECT count(*) AS count
         FROM tree p
         WHERE p.path ~ ('^'::text || tree.path) AND NOT p.path = tree.path) AS blocked
--       (repeat(''::text, tree.lvl) || ' '::text) || "left"(regexp_replace(a.query, '[\\n\\r\\t]+'::text, ' '::text, 'g'::text), 100) AS query
FROM tree JOIN pg_stat_activity a USING (pid)
ORDER BY tree.path;



--check Connections 
select coalesce(usename, 'total') as usename
, case when grouping(usename) = 1 then -2 else max (rolconnlimit) end as rolconnlimit
, string_agg(distinct case when state = 'idle in transaction' then 'iit' else state end, '/') as session_state
, sum(case when state = 'active' then 1 else 0 end) as act_count
, sum(case when state = 'idle' then 1 else 0 end) as idl_count
, sum(case when state = 'idle in transaction' then 1 else 0 end) as iit_count
, abs(case when max(rolconnlimit) = -1 or grouping(usename) = 1 then 0 else max(rolconnlimit) end
	- (sum(case when state = 'active' then 1 else 0 end)
	+ sum(case when state = 'idle' then 1 else 0 end) 
	+ sum(case when state = 'idle in transaction' then 1 else 0 end)))::text
	|| case when grouping(usename) = 1 or max(rolconnlimit) = -1 then ' used' else ' left' end as "conn_left/used"
from pg_stat_activity join pg_roles on usename = rolname 
where usename <> 'rdsadmin' 
group by grouping sets ((usename), ())
order by rolconnlimit desc, usename;


-- Show tables with vacuum stats and time since last vacuum
SELECT
    schemaname,
    relname AS table_name,
    last_vacuum,
    last_autovacuum,
    CASE 
        WHEN last_vacuum IS NULL AND last_autovacuum IS NULL THEN 'Never vacuumed'
        WHEN last_vacuum > last_autovacuum OR last_autovacuum IS NULL THEN 
            'Manual: ' || age(now(), last_vacuum)::text
        ELSE 
            'Auto: ' || age(now(), last_autovacuum)::text
    END AS time_since_vacuum,
    n_dead_tup AS dead_tuples,
    n_live_tup AS live_tuples,
    ROUND(100.0 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0), 2) AS dead_tuple_percent,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||relname)) AS table_size,
    vacuum_count,
    autovacuum_count
FROM pg_stat_user_tables
where schemaname = 'bluebox'
ORDER BY n_dead_tup DESC;


--TXN Wraparound
-- Query to monitor maximum XID age across databases
-- 400000000 is a warning threshold, adjust as needed based on your workload and maintenance schedule
SELECT datname, age(datfrozenxid) as xid_age
FROM pg_database
ORDER BY xid_age DESC;


--From Crunchy Data
--https://www.crunchydata.com/blog/monitoring-postgresql-xid-wraparound-risk
WITH max_age AS (
    SELECT 2000000000 as max_old_xid
        , setting AS autovacuum_freeze_max_age
        FROM pg_catalog.pg_settings
        WHERE name = 'autovacuum_freeze_max_age' )
, per_database_stats AS (
    SELECT datname
        , m.max_old_xid::int
        , m.autovacuum_freeze_max_age::int
        , age(d.datfrozenxid) AS oldest_current_xid
    FROM pg_catalog.pg_database d
    JOIN max_age m ON (true)
    WHERE d.datallowconn )
SELECT max(oldest_current_xid) AS oldest_current_xid
    , max(ROUND(100*(oldest_current_xid/max_old_xid::float))) AS percent_towards_wraparound
    , max(ROUND(100*(oldest_current_xid/autovacuum_freeze_max_age::float))) AS percent_towards_emergency_autovac
FROM per_database_stats

--Check stats
SELECT schemaname,relname as tablename, last_autoanalyze, last_autovacuum, 
last_analyze, last_vacuum,
pg_size_pretty(pg_total_relation_size(schemaname||'.'||relname)) AS table_size 
FROM pg_stat_all_tables 
where schemaname = 'bluebox'
order by last_analyze desc;


--check wait events
select
--usename,
wait_event,
state,
count(*),
Min((now() - pg_stat_activity.xact_start)) AS "Min Transaction duration",
Max((now() - pg_stat_activity.xact_start)) AS "Max Transaction duration",
avg((now() - pg_stat_activity.xact_start)) AS "Avg Transaction duration",
Min((now() - pg_stat_activity.query_start)) AS "Min Query age",
Max((now() - pg_stat_activity.query_start)) AS "Max Query age",
avg((now() - pg_stat_activity.query_start)) AS "Avg Query age",
(select count(*) used from pg_stat_activity) as total_count
from pg_stat_activity
where (pg_stat_activity.application_name <> ALL (ARRAY['vacuumdb'::text, 'pg_dump'::text]))
and (wait_event_type is not null )
AND (pg_stat_activity.backend_type = ANY (ARRAY['client backend'::text]))
--and state in ('idle','idle in transaction')
group by
wait_event,
state
order by count(*) desc,
wait_event,
state;

--replication slot status and lag
SELECT prs.slot_name, (''::text || round(pg_wal_lsn_diff(pg_current_wal_lsn(), prs.restart_lsn) / (1024 * 1024 * 1024)::numeric)) || ''::text AS "WAL on Master", 
prs.slot_type AS "Slot Type", 
CASE WHEN prs.active = true THEN 'TRUE'::text ELSE 'FALSE'::text END AS "Active", psr.state, 
(''::text || round(pg_wal_lsn_diff(pg_current_wal_lsn(), psr.replay_lsn) / (1024 * 1024 * 1024)::numeric)) || ''::text AS "WAL on Replica",
COALESCE(round(date_part('epoch'::text, psr.replay_lag) / 60::double precision), NULL::double precision, 0::double precision) AS log_delay, 
prs.database
FROM pg_replication_slots prs LEFT JOIN pg_stat_replication psr ON prs.active_pid = psr.pid 
ORDER BY prs.active, psr.application_name, psr.pid; 