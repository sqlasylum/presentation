-- Query pg_stat_statements for performance insights

-- Top 20 queries by total execution time
SELECT 
    queryid,
    LEFT(query, 80) AS query_snippet,
    calls,
    ROUND(total_exec_time::numeric, 2) AS total_time_ms,
    ROUND(mean_exec_time::numeric, 2) AS avg_time_ms,
    ROUND(max_exec_time::numeric, 2) AS max_time_ms,
    ROUND(min_exec_time::numeric, 2) AS min_time_ms,
    rows,
    ROUND((100.0 * total_exec_time / SUM(total_exec_time) OVER())::numeric, 2) AS percent_total
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 20;

-- Top 20 queries by average execution time
SELECT 
    queryid,
    LEFT(query, 80) AS query_snippet,
    calls,
    ROUND(mean_exec_time::numeric, 2) AS avg_time_ms,
    ROUND(total_exec_time::numeric, 2) AS total_time_ms,
    ROUND(max_exec_time::numeric, 2) AS max_time_ms
FROM pg_stat_statements
WHERE calls > 10  -- Filter out rarely called queries
ORDER BY mean_exec_time DESC
LIMIT 20;

-- Top 20 most frequently called queries
SELECT 
    queryid,
    LEFT(query, 80) AS query_snippet,
    calls,
    ROUND(mean_exec_time::numeric, 2) AS avg_time_ms,
    ROUND(total_exec_time::numeric, 2) AS total_time_ms,
    rows
FROM pg_stat_statements
ORDER BY calls DESC
LIMIT 20;

-- Queries with highest variability (difference between max and mean time)
SELECT 
    queryid,
    LEFT(query, 80) AS query_snippet,
    calls,
    ROUND(mean_exec_time::numeric, 2) AS avg_time_ms,
    ROUND(max_exec_time::numeric, 2) AS max_time_ms,
    ROUND((max_exec_time - mean_exec_time)::numeric, 2) AS variability_ms
FROM pg_stat_statements
WHERE calls > 10
ORDER BY (max_exec_time - mean_exec_time) DESC
LIMIT 20;

-- Summary statistics
SELECT 
    COUNT(*) AS total_queries,
    SUM(calls) AS total_calls,
    ROUND(SUM(total_exec_time)::numeric, 2) AS total_exec_time_ms,
    ROUND(AVG(mean_exec_time)::numeric, 2) AS overall_avg_time_ms
FROM pg_stat_statements;
