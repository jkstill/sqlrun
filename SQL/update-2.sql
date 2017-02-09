

update ( 
	select id, c1
	from sql_class
	where mod(id, 42) = 0
)
set c1 = dbms_random.string('L',floor(dbms_random.value(10,33)))

