
-- rc for  result cache
-- when client side result cache is used, and it working, nothing appears in the trace file.
-- use this table and function to record number of operations

drop table rc_logging cascade constraints purge;

create table rc_logging
(
	id number not null,
	start_time date not null,
	op_count number not null
)
/


create or replace procedure update_op_count
is
	audit_id number;
	rcount pls_integer;
begin
	audit_id := sys_context('userenv','unified_audit_sessionid');

	select count(*) into rcount from rc_logging where id = audit_id;

	if rcount = 1 then 
		update rc_logging set op_count = op_count + 1 where id = audit_id;
	else
		insert into rc_logging(id, start_time, op_count)
		values(audit_id,sysdate,1);
	end if;

	commit;
	
end;
/

show error procedure update_op_count

