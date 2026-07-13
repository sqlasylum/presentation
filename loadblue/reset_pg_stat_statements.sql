-- Reset pg_stat_statements statistics
-- Use this to clear statistics and start fresh monitoring

-- Show current statistics count before reset
SELECT COUNT(*) AS queries_tracked FROM pg_stat_statements;

-- Reset all statistics
SELECT pg_stat_statements_reset();

-- Verify reset
SELECT COUNT(*) AS queries_tracked_after_reset FROM pg_stat_statements;

-- Note: After running this, statistics will start accumulating from zero
