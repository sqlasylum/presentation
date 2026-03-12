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
ORDER BY n_dead_tup DESC;


--Analyze stats 
SELECT schemaname,relname as tablename, last_autoanalyze, last_autovacuum, last_analyze, last_vacuum FROM pg_stat_all_tables where (schemaname not like '%temp%' and schemaname not like '%toast%') and last_analyze is not null and schemaname = 'public' order by last_analyze desc limit 10;
--Last vacuum variation 
select min(last_vacuum),max(last_vacuum) from pg_stat_all_tables where schemaname = 'public';