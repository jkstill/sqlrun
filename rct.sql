
col owner format a20
col table_name format a30
col result_cache format a15 head 'RESULT|CACHE'

select owner, table_name, result_cache
from dba_tables
--where owner = 'JKSTILL'
--and table_name in ('CHAIR','HOLIDAY')
where owner = 'EVS'
order by 1,2
/

