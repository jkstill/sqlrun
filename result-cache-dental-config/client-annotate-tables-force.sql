

-- for clients that have result cache enabled, force the use of result cache on these tables

alter table chair result_cache (mode force);
alter table holiday result_cache (mode force);


