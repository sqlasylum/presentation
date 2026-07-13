-- Setup pg_stat_statements extension for query performance monitoring
-- This extension provides a means for tracking planning and execution statistics
-- of all SQL statements executed by a server.

show 


-- Create the extension (requires superuser privileges)
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Verify the extension was created
SELECT * FROM pg_extension WHERE extname = 'pg_stat_statements';

-- Show current pg_stat_statements settings
SHOW pg_stat_statements.track;
SHOW pg_stat_statements.max;

-- Display information about the pg_stat_statements view
\d pg_stat_statements

-- Sample query to see current statistics (will be empty initially)
SELECT 
    queryid,
    query,
    calls,
    total_exec_time,
    mean_exec_time,
    max_exec_time,
    min_exec_time,
    rows
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;
