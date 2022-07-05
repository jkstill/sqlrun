
drop table sqlrun_gtt purge;

create global temporary table sqlrun_gtt
on commit delete rows
as
select * from all_objects 
where 1=0;



