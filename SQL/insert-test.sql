

declare
   xid integer;
   t1 timestamp;
   t2 timestamp;
   t3 timestamp;
   tdiff1 number;
   tdiff2 number;
begin
   t1 := systimestamp;

   xid := sqlrun_insert_seq.nextval;

   insert into sqlrun_insert(id,sql_timestamp,tag)
   values(xid, t1, sys_context('SQLRUN','TAG'));

   t2 := systimestamp;

   tdiff1 := extract(second from (t2 - t1));

   commit;

   t3 := systimestamp;

   tdiff2 := extract(second from (t3 - t2));

   update sqlrun_insert
   set
      response_time_insert = tdiff1 * 1000000,
      response_time_commit = tdiff2 * 1000000
   where id = xid;

   commit;

end;


