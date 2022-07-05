
-- empty unless temp_undo_enabled = TRUE

select begin_time, end_time, txncount, uscount
from v$tempundostat
order by 1
/
