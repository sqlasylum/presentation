
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
and state = 'active'
--and usename = 'specfic_user'
order by 5 desc,application_name, 3;



