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