
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