set echo on
create user EVS identified by evs default tablespace EVS temporary tablespace TEMP;
alter user EVS quota  UNLIMITED  on EVS;
grant ALTER SESSION to EVS ;
grant ALTER SYSTEM to EVS ;
grant ANALYZE ANY DICTIONARY to EVS ;
grant ANALYZE ANY to EVS ;
grant CREATE JOB to EVS ;
grant CREATE PROCEDURE to EVS ;
grant CREATE SEQUENCE to EVS ;
grant CREATE SESSION to EVS ;
grant CREATE TABLE to EVS ;
grant CREATE VIEW to EVS ;
grant EXECUTE on SYS.DBMS_LOCK to EVS;
grant MANAGE ANY QUEUE to EVS ;
grant MANAGE SCHEDULER to EVS ;
grant READ on directory SYS.TESTDIR to EVS;
grant RESOURCE to EVS;
grant SELECT on SYS.V_$PARAMETER to EVS;
grant plustrace to evs;

grant select on v_$instance to evs;
grant select on v_$diag_info to evs;


