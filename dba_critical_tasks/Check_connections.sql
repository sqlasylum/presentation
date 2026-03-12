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