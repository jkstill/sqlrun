
drop sequence sqlrun_insert_seq;
drop table sqlrn

create sequence sqlrun_insert_seq cache 10000;

create table sqlrun_insert (
	id integer,
	sql_timestamp timestamp,
	tag varchar2(16),
	response_time_insert integer,
	response_time_commit integer
)
/

create unique index sqlrun_insert_u_idx on sqlrun_insert(id);



