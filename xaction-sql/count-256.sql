

set tab off echo off pause off
set feed on term on
set linesize 200 trimspool on
set pagesize 100

btitle off
ttitle off
clear compute
clear break

col min_insert_time format 99,999,999 head 'MIN|INSERT|TIME'
col max_insert_time format 99,999,999 head 'MAX|INSERT|TIME'
col avg_insert_time format 99,999,999  head 'AVG|INSERT|TIME'
col median_insert_time format 99,999,999  head 'MED|INSERT|TIME'
col min_commit_time format 99,999,999 head 'MIN|COMMIT|TIME'
col max_commit_time format 99,999,999 head 'MAX|COMMIT|TIME'
col avg_commit_time format 99,999,999 head 'AVG|COMMIT|TIME'
col median_commit_time format 99,999,999 head 'MED|COMMIT|TIME'
col sla format 99,999,999


with data as (
	select tag
		, count(*) rowcount
		, min(response_time_insert) min_insert_time
		, max(response_time_insert) max_insert_time
		, avg(response_time_insert) avg_insert_time
		, median(response_time_insert) median_insert_time
		, min(response_time_commit) min_commit_time
		, max(response_time_commit) max_commit_time
		, avg(response_time_commit) avg_commit_time
		, median(response_time_commit) median_commit_time
	from sqlrun_insert
	where ( tag like 'DRCP-256-%' or tag = 'SQLRUN-256' )
	group by tag
)
select tag
	, rowcount
	, min_insert_time
	, max_insert_time
	, avg_insert_time
	, median_insert_time
	, min_commit_time
	, max_commit_time
	, avg_commit_time
	, median_commit_time
	, avg_commit_time + avg_insert_time sla
from data
order by tag
/
