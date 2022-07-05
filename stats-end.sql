


update stats_end e
set (e.value) = (
	select st.value new_value
	from v$session s
	join v$sesstat st on st.sid = s.sid
   	and s.username = 'UNDOTEST'
		and s.sid = e.sid
	join v$statname n on n.statistic# = st.statistic#
		and n.name = e.name
)
where exists (
	select 1 from v$session where sid = e.sid
)
/

commit;

