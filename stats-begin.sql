
drop table stats_begin purge;

create table stats_begin
as
select s.sid, n.name, st.value
from v$session s
join v$sesstat st on st.sid = s.sid
   and s.username = 'UNDOTEST'
join v$statname n on n.statistic# = st.statistic#
   and n.name in ('redo size','undo change vector size')
/


drop table stats_end purge;

create table stats_end
as
select s.sid, n.name, st.value
from v$session s
join v$sesstat st on st.sid = s.sid
   and s.username = 'UNDOTEST'
join v$statname n on n.statistic# = st.statistic#
   and n.name in ('redo size','undo change vector size')
/



