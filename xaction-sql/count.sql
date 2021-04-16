
col min_insert_time format 99,999,999
col max_insert_time format 99,999,999
col avg_insert_time format 99,999,999
col min_commit_time format 99,999,999
col max_commit_time format 99,999,999
col avg_commit_time format 99,999,999
col sla format 99,999,999


with data as (
	select tag
		, count(*) rowcount
		, min(response_time_insert) min_insert_time
		, max(response_time_insert) max_insert_time
		, avg(response_time_insert) avg_insert_time
		, min(response_time_commit) min_commit_time
		, max(response_time_commit) max_commit_time
		, avg(response_time_commit) avg_commit_time
	from sqlrun_insert group by tag
)
select tag
	, rowcount
	, min_insert_time
	, max_insert_time
	, avg_insert_time
	, min_commit_time
	, max_commit_time
	, avg_commit_time
	, avg_commit_time + avg_insert_time sla
from data
order by tag
/
