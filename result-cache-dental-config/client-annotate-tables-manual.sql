

-- for clients that have result cache enabled, disable forced use of result cache on these tables

alter table chair result_cache (mode manual);
alter table holiday result_cache (mode manual);



