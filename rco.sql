
-- rco.sql
-- result cache objects

set linesize 200 trimspool on
set pagesize 100

col namespace format a5
col status format a12
col name format a40
col avg_scan_cnt format 999999.9 head 'Avg|Scan|Cnt'
col max_scan_cnt format 99999999 head 'Max|Scan|Cnt'
col total_blk_cnt format 99999999 head 'Total|Block|Cnt'
col number_of_results format 999,999 head 'Number|of|Results'

select 
	namespace,
	status,
	name,
	count(*) number_of_results,
	round(avg(scan_count)) avg_scan_cnt,
	round(max(scan_count)) max_scan_cnt,
	round(sum(block_count)) tot_blk_cnt
	from v$result_cache_objects
where type = 'Result'
	and status = 'Published'
group by namespace, name, status
order by namespace, tot_blk_cnt
/
