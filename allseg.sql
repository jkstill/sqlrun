
-- v$tempundostat empty unless temp_undo_enabled = TRUE

select p.begin_time, p.end_time, p.txncount, t.txncount, t.uscount
from v$undostat p
left outer join  v$tempundostat t
	on t.begin_time = p.end_time
order by 1
/
