
col name format a40
col value format 999,999,999,990

-- not using inst_id due to 19c bug
-- ORA-12850 when querying RAC instances

with begin_data as
(
	select name, sum(value) value
	from stats_begin
	group by name
),
end_data as (
	select name, sum(value) value
	from stats_end
	group by name
)
select 
	e.name
	, e.value - b.value value
	, (select nvl(sum(txacts),0) from undotest.txcount) txcount
	from end_data e
join begin_data b 
	on b.name = e.name
order by e.name
/

