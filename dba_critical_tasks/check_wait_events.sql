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
