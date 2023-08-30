
-- 1 minute 
-- the annotated tables are CHAIR and HOLIDAY
-- both are smalle and nearly static
alter system set client_result_cache_lag = 60000 scope=spfile sid='*';


-- must be at least 32k to enable the client cache
-- can be altered at the client session
-- if that is not possible, just increase the size of this parameter
alter system set client_result_cache_size = 1M scope=spfile sid='*';

