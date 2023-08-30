

-- for clients that have result cache enabled, force the use of result cache on these tables

alter table cities result_cache (mode force);
alter table ev_models result_cache (mode force);
alter table ev_locations result_cache (mode force);


