
-- v$tempundostat empty unless temp_undo_enabled = TRUE

col permtxcount format 999999 head 'PERM|UNDO'
col temptxcount format 999999 head 'TEMP|UNDO'
col permundoblocks format 999999 head 'PERM|UNDO|BLKS'
col tempundoblocks format 999999 head 'TEMP|UNDO|BLKS'

select 
	p.begin_time, p.end_time
	, p.undoblks permundoblocks 
	, p.txncount permtxcount
	, t.txncount temptxcount
	--, t.uscount
	, t.undoblkcnt tempundoblocks
from v$undostat p
left outer join  v$tempundostat t
	on t.begin_time = p.begin_time
where p.begin_time between to_date('2022-07-05 12:45:00', 'yyyy-mm-dd hh24:mi:ss') and to_date('2022-07-05 16:45:00', 'yyyy-mm-dd hh24:mi:ss')
order by 1
/
