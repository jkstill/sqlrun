-- merge 500 new rows and update 500 more
merge into sql_class sc
using (
	with data as (
		select 
			level id,
			dbms_random.string('L',floor(dbms_random.value(10,33))) c1
		from dual
		connect by level <= 5000
	)
	select * from data d
	where d.id > 4500
) new_data
on (new_data.id = sc.id)
when matched then update set sc.c1 = dbms_random.string('L',floor(dbms_random.value(10,33)))
when not matched then insert (sc.id, sc.c1)
	values(new_data.id, new_data.c1)

