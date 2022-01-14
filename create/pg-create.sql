
create table public.sqlrun_test (id int, c1 varchar(30));

INSERT INTO public.sqlrun_test(id, c1)
SELECT id,  substring(md5(random()::text),1,30)
FROM generate_series(1,10000) id;

create unique index sqlrun_test_idx on public.sqlrun_test(id);

