select count(*),application_name,datname, usename,state 
from pg_stat_activity 
where (usename IS NOT NULL and datname IS NOT NULL and USENAME <> 'rdsadmin')
and state = 'active'
group by 2,3,4,5 
order by 5,1 desc, 1 desc;