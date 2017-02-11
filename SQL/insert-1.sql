-- insert 500 new rows
insert into sql_class ( id, c1)
with data as (
	select 
		level id,
		dbms_random.string('L',floor(dbms_random.value(10,33))) c1
	from dual
	connect by level <= 2500
)
select * from data d
where d.id > 2000
