SELECT schemaname,relname as tablename, last_autoanalyze, last_autovacuum, 
last_analyze, last_vacuum,
pg_size_pretty(pg_total_relation_size(schemaname||'.'||relname)) AS table_size 
FROM pg_stat_all_tables 
where schemaname = 'bluebox'
order by last_analyze desc;



