
-- contents unimportant

drop table sql_class purge;
drop table plsql_test purge;

exec dbms_random.seed(sys_context('userenv','sessionid'))

-- 1000 rows
create table sql_class
as
select 
	level id,
	dbms_random.string('L',floor(dbms_random.value(10,33))) c1
from dual
connect by level <= 1000;

create index sql_class_pk on sql_class(id);

alter table sql_class add constraint sql_class_pk primary key(id);

exec dbms_stats.gather_table_stats(null,'SQL_CLASS')

-- plsql test table

create table plsql_test (
	c1 varchar2(30),
	c2 integer
)
/



