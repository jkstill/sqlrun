
select id, c1
from public.sqlrun_test
where id = (select (random() * 10000)::integer)
