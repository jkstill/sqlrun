select begin_time, end_time, txncount
from v$undostat
order by 1
/
