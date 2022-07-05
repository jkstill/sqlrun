merge into txcount tx
	using (select sys_context('userenv','sid') sid from dual ) s
	on (s.sid = tx.sid)
when matched then 
	update set tx.txacts = tx.txacts + 1
when not matched then 
	insert (sid, txacts)
	values(sys_context('userenv','sid'),1)
