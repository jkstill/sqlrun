sqlrun
======


sqlrun.pl is a Perl script and related modules that can be used to run multiple SQL statements from a number of sessions.

## What's new?

* --tracefile-id Specify the tracefile id
* --driver use a driver other than Oracle.  SQLRelay, mysql, etc
* --context-tag make use of SYS_CONTEXT() in some tests.
* --drcp indicate that this is a DRCP connection
         this will still require ':pooled' in the connection string
         may be a bug in DBD::Oracle (as of 1.80)
* --awr  snapshot and baseline options

## Options

```text
usage: sqlrun.pl

               --db  which database to connect to
           --driver  which DBD Driver to use. defaults to 'Oracle'
			            use 'SQLRelay' when connecting via SQL Relay connection pool
      --tx-behavior  for DML - [rollback|commit] - default is rollback
                     commit or rollback is peformed after every DML transaction
         --username  account to connect to
         --password  obvious. 
                     user will be prompted for password if not on the command line
 
             --drcp  connect via DRCP (see DBD:Oracle docs)
       --drcp-class  set the classname for the DRCP connection (optional)
 
                     DRCP: setting the {ora_drcp => 1} connection attribute as per the DBD::Oracle
                           docs is not working as documented, as of the latest version, 1.80.
                            
                           it is necessary to append ':pooled' to the connection name for a DRCP connection
 
     --max-sessions  number of sessions to use
 
        --exe-delay  seconds to delay between sql executions defaults to 0.1 seconds
 
    --connect-delay  seconds to delay be between connections
                     valid only for --session-mode trickle
 
     --connect-mode  [ trickle | flood | tsunami ] - default is flood
                     trickle: gradually add sessions up to max-sessions
                     flood: startup sessions as quickly as possible
                     tsunami: wait until all sessions are connected before they are allowed to work
 
      --context-tag  set a value for the TAG attribute in the SQLRUN namespace
                     before using this the SQLRUN_CONTEXT package must be created (see the create directory)
                     see create/create-insert-test.sql, SQL/insert-test.sql and ./sqlrun-context.sh
 
                     there is no default value for this option
 
         --exe-mode  [ sequential | semi-random | truly-random ] - default is sequential
                     sequential: each session iterates through the SQL statements serially
                     semi-random: a value assigned in the sqlfile determines how frequently each SQL is executed
                     truly-random: SQL selected randomly by each session
 
           --sqldir  location of SQL script files and bind variable files. 
                     default is .\/SQL
 
          --sqlfile  this refers to the file that names the SQL script files to use 
                     the names of the bind variable files will be defined here as well
                     default is .\/sqlfile.conf
 
          -parmfile  file containing session parameters to set
                     see example parameters.conf
 
          --runtime  how long (in seconds) the jobs should run
                     the timer starts when the first session starts
 
  --bind-array-size  defines how many records from the bind array file are to be used per SQL execution
                     default is 1
                     Note: not yet implemented
 
 --cache-array-size  defines the size of array to use to retreive data - similar to 'set array' in sqlplus 
                     default is 100
 
           --sysdba  connect as sysdba
          --sysoper  connect as sysoper
           --schema  do 'alter session set current_schema' to this schema
                     useful when you need to connect as sysdba and do not wish to modify SQL to fully qualify object names
 
            --trace  enable 10046 trace with binds - sets tracefile_identifier to SQLRUN-timestamp
     --tracefile-id  tag tracefile names via tracefile identifier - defaults to 'SQLRUN'
 
    --awr-baseline  create an AWR snapshot before and after the tests.  
	                 the default AWR flush level is 'ALL'
 
--awr-baseline-tag  the prefix used for the AWR baseline name - default is 'SQLRUN'
                    baselines will be named as 'TAG-MAX_CONNECTIONS'
                    sqlrun will exit with an error if the 30 character name limit is exceeded
						  
                    ex: if testing with 20 pooled servers and 200 connections, a tag of 'DRCP-20' 
                        would result in 'DRCP-20-200' as the baseline name
 
--awr-baseline-expires 
                    time in days for the AWR Baseline to expire - defaults to 30

 --awr-flush-level for 12c - 'ALL' or 'TYPICAL'.  19c additionally has 'BESTFIT' and 'LITE'

--awr-baseline-delete-existing
                   delete an an existing baseline if there is a naming conflict
                   default is to NOT delete, but raise an error

           --debug  enables some debugging output
    --exit-trigger  used to trigger 'exit' code that may be present for debugging


  example:

  sqlrun -db dv07 -username scott -password tiger -sysdba 
		
sqlrun \
	--exe-mode semi-random \
	--connect-mode flood \
	--connect-delay 2 \
	--max-sessions 20 \
	--db p1 \
	--username sys \
	--password sys \
	--schema scott \
	--sysdba \
	--parmfile parameters.conf \
	--sqlfile sqlfile.conf  \
	--runtime 20

  SQL Relay connection:

  sqlrun -db "host=sqlrelay;port=9000;tries=0;retrytime=1;debug=0" -username sqlruser -password sqlruser 


PL/SQL:

PL/SQL can be used.

It is up to you to include a commit or rollback as necessary within the PL/SQL as required

see examples in the SQL directory


```

## ToDo 

- ensure login via wallet works (may already work)
- store password in encrypted file (if no wallet available)
- add --display-output flag for SELECT
- add --tx-frequency to control rate of commit or rollback
- add option to retrieve trace files automatically
- pre and post SQL - statements to run once before and after the tests
- AWR Snapshot and Baseline. Create a snapshot before and after tests
  and a self expiring AWR Baseline


## DML

DML statements can be used as well.
As with SELECT there is a limit of 1 statement per file.
A bind variable file may also be used.

Use the --tx-behavior option to control whether to commit or rollback.

## PL/SQL

PL/SQL consists of a 'begin end' block, or a 'declare begin end' block.

Bind variables may be used.

If commit or rollback is needed, it should be included in the PL/SQL block.


## Test Run SELECT only

This is using the example configuration file with the following lines uncommmented:

```text
2,sql-1.sql,
3,sql-2.sql
5,sql-3.sql,sql-3-binds.txt
2,sql-4.sql,sql-4-binds.txt
1,sql-system-1.sql,
```

```text
./sqlrun.pl \
        --exe-mode semi-random \
        --connect-mode flood \
        --connect-delay 2 \
        --max-sessions 20 \
        --db p1 \
        --username scott \
        --password tiger \
        --schema system \
        --sysdba \
        --parmfile parameters.conf \
        --sqlfile sqlfile.conf  \
        --runtime 10


Connection Test - SYS - 72

SQL PARSER:

DEBUG: 0
sqlParmFileFQN:  SQL/sqlfile.conf
exeMode: semi-random

Connect Mode: flood
PID: 25517
Waiting on child 25517...
PID: 0
PID: 25519
Waiting on child 25519...
PID: 0
PID: 25521
Waiting on child 25521...
PID: 0
PID: 25523
Waiting on child 25523...
PID: 0
PID: 25525
Waiting on child 25525...
PID: 0
PID: 25527
Waiting on child 25527...
PID: 0
PID: 25529
Waiting on child 25529...
PID: 0
PID: 25531
Waiting on child 25531...
PID: 0
PID: 25533
Waiting on child 25533...
PID: 0
PID: 25535
Waiting on child 25535...
PID: 0
PID: 25537
Waiting on child 25537...
PID: 0
PID: 25539
Waiting on child 25539...
PID: 0
PID: 25541
Waiting on child 25541...
PID: 0
PID: 25543
Waiting on child 25543...
PID: 0
PID: 25545
Waiting on child 25545...
PID: 0
PID: 25551
Waiting on child 25551...
PID: 0
PID: 25553
Waiting on child 25553...
PID: 0
PID: 25555
Waiting on child 25555...
PID: 0
PID: 25557
Waiting on child 25557...
PID: 0
PID: 25559
Waiting on child 25559...
PID: 0
 ~/oracle/sqlrun $

 ~/oracle/sqlrun $ ps
  PID TTY          TIME CMD
12696 pts/3    00:00:00 bash
25518 pts/3    00:00:00 perl
25520 pts/3    00:00:00 perl
25522 pts/3    00:00:00 perl
25524 pts/3    00:00:00 perl
25526 pts/3    00:00:00 perl
25528 pts/3    00:00:00 perl
25530 pts/3    00:00:00 perl
25532 pts/3    00:00:00 perl
25534 pts/3    00:00:00 perl
25536 pts/3    00:00:00 perl
25538 pts/3    00:00:00 perl
25540 pts/3    00:00:00 perl
25542 pts/3    00:00:00 perl
25544 pts/3    00:00:00 perl
25546 pts/3    00:00:00 perl
25552 pts/3    00:00:00 perl
25554 pts/3    00:00:00 perl
25556 pts/3    00:00:00 perl
25558 pts/3    00:00:00 perl
25560 pts/3    00:00:00 perl
25565 pts/3    00:00:00 ps
```

Here is another test using the --trace option

```text

./sqlrun.pl \
         --exe-mode semi-random \
         --connect-mode flood \
         --connect-delay 2 \
         --max-sessions 20 \
         --db p1 \
         --username scott \
         --password tiger \
         --schema system \
         --sysdba \
         --parmfile parameters.conf \
         --sqlfile sqlfile.conf  \
         --runtime 10 \
         --trace \
			--tracefile-id 'SQLRUN-20-10'

Connection Test - SYS - 90


SQL PARSER:

DEBUG: 0
sqlParmFileFQN:  SQL/sqlfile.conf
exeMode: semi-random

tracefile_identifier = SQLRUN-20-10-20170001123638
Connect Mode: flood
PID: 25676
Waiting on child 25676...
PID: 0
PID: 25678
Waiting on child 25678...
PID: 0
PID: 25680
Waiting on child 25680...
PID: 0
PID: 25682
Waiting on child 25682...
PID: 0
PID: 25684
Waiting on child 25684...
PID: 0
PID: 25686
Waiting on child 25686...
PID: 0
PID: 25688
Waiting on child 25688...
PID: 0
PID: 25690
Waiting on child 25690...
PID: 0
PID: 25692
Waiting on child 25692...
PID: 0
PID: 25694
Waiting on child 25694...
PID: 0
PID: 25696
Waiting on child 25696...
PID: 0
PID: 25698
Waiting on child 25698...
PID: 0
PID: 25700
Waiting on child 25700...
PID: 0
PID: 25702
Waiting on child 25702...
PID: 0
PID: 25704
Waiting on child 25704...
PID: 0
PID: 25706
Waiting on child 25706...
PID: 0
PID: 25708
Waiting on child 25708...
PID: 0
PID: 25710
Waiting on child 25710...
PID: 0
PID: 25712
Waiting on child 25712...
PID: 0
PID: 25714
Waiting on child 25714...
PID: 0


Trace File: ora12c102rac01.jks.com./u01/cdbrac/app/oracle/diag/rdbms/js122a/js122a1/trace/js122a1_ora_23607_SQLRUN-20-10-20170001123638.trc
Trace File: ora12c102rac01.jks.com./u01/cdbrac/app/oracle/diag/rdbms/js122a/js122a1/trace/js122a1_ora_23609_SQLRUN-20-10-20170001123638.trc
Trace File: ora12c102rac01.jks.com./u01/cdbrac/app/oracle/diag/rdbms/js122a/js122a1/trace/js122a1_ora_23613_SQLRUN-20-10-20170001123638.trc
Trace File: ora12c102rac01.jks.com./u01/cdbrac/app/oracle/diag/rdbms/js122a/js122a1/trace/js122a1_ora_23611_SQLRUN-20-10-20170001123638.trc
Trace File: ora12c102rac02.jks.com./u01/cdbrac/app/oracle/diag/rdbms/js122a/js122a2/trace/js122a2_ora_17059_SQLRUN-20-10-20170001123638.trc
Trace File: ora12c102rac01.jks.com./u01/cdbrac/app/oracle/diag/rdbms/js122a/js122a1/trace/js122a1_ora_23615_SQLRUN-20-10-20170001123638.trc
Trace File: ora12c102rac01.jks.com./u01/cdbrac/app/oracle/diag/rdbms/js122a/js122a1/trace/js122a1_ora_23617_SQLRUN-20-10-20170001123638.trc
Trace File: ora12c102rac01.jks.com./u01/cdbrac/app/oracle/diag/rdbms/js122a/js122a1/trace/js122a1_ora_23621_SQLRUN-20-10-20170001123638.trc
Trace File: ora12c102rac02.jks.com./u01/cdbrac/app/oracle/diag/rdbms/js122a/js122a2/trace/js122a2_ora_17061_SQLRUN-20-10-20170001123638.trc
Trace File: ora12c102rac01.jks.com./u01/cdbrac/app/oracle/diag/rdbms/js122a/js122a1/trace/js122a1_ora_23619_SQLRUN-20-10-20170001123638.trc
Trace File: ora12c102rac02.jks.com./u01/cdbrac/app/oracle/diag/rdbms/js122a/js122a2/trace/js122a2_ora_17065_SQLRUN-20-10-20170001123638.trc
Trace File: ora12c102rac02.jks.com./u01/cdbrac/app/oracle/diag/rdbms/js122a/js122a2/trace/js122a2_ora_17063_SQLRUN-20-10-20170001123638.trc
Trace File: ora12c102rac02.jks.com./u01/cdbrac/app/oracle/diag/rdbms/js122a/js122a2/trace/js122a2_ora_17067_SQLRUN-20-10-20170001123638.trc
Trace File: ora12c102rac02.jks.com./u01/cdbrac/app/oracle/diag/rdbms/js122a/js122a2/trace/js122a2_ora_17069_SQLRUN-20-10-20170001123638.trc
Trace File: ora12c102rac02.jks.com./u01/cdbrac/app/oracle/diag/rdbms/js122a/js122a2/trace/js122a2_ora_17071_SQLRUN-20-10-20170001123638.trc
Trace File: ora12c102rac02.jks.com./u01/cdbrac/app/oracle/diag/rdbms/js122a/js122a2/trace/js122a2_ora_17073_SQLRUN-20-10-20170001123638.trc
Trace File: ora12c102rac02.jks.com./u01/cdbrac/app/oracle/diag/rdbms/js122a/js122a2/trace/js122a2_ora_17075_SQLRUN-20-10-20170001123638.trc
Trace File: ora12c102rac02.jks.com./u01/cdbrac/app/oracle/diag/rdbms/js122a/js122a2/trace/js122a2_ora_17079_SQLRUN-20-10-20170001123638.trc
Trace File: ora12c102rac02.jks.com./u01/cdbrac/app/oracle/diag/rdbms/js122a/js122a2/trace/js122a2_ora_17077_SQLRUN-20-10-20170001123638.trc
Trace File: ora12c102rac02.jks.com./u01/cdbrac/app/oracle/diag/rdbms/js122a/js122a2/trace/js122a2_ora_17081_SQLRUN-20-10-20170001123638.trc

~/oracle/sqlrun $ ps
  PID TTY          TIME CMD
12696 pts/3    00:00:00 bash
25677 pts/3    00:00:00 perl
25679 pts/3    00:00:00 perl
25681 pts/3    00:00:00 perl
25683 pts/3    00:00:00 perl
25685 pts/3    00:00:00 perl
25687 pts/3    00:00:00 perl
25689 pts/3    00:00:00 perl
25691 pts/3    00:00:00 perl
25693 pts/3    00:00:00 perl
25695 pts/3    00:00:00 perl
25697 pts/3    00:00:00 perl
25699 pts/3    00:00:00 perl
25701 pts/3    00:00:00 perl
25703 pts/3    00:00:00 perl
25705 pts/3    00:00:00 perl
25707 pts/3    00:00:00 perl
25709 pts/3    00:00:00 perl
25711 pts/3    00:00:00 perl
25713 pts/3    00:00:00 perl
25715 pts/3    00:00:00 perl
25720 pts/3    00:00:00 ps

```

## Test Run with DML and PL/SQL

Be sure the following lines in SQL/sqlfile.conf are uncommented

```text
1,select-1.sql,
1,select-2.sql,
1,insert-1.sql,
1,insert-2.sql,
1,merge.sql,
1,delete.sql,
1,update-1.sql,
1,update-2.sql,
1,plsql-1.sql,
1,plsql-2.sql,
1,plsql-binds.sql,plsql-binds.txt
```

create the test tables with SQL/create.sql

Now run the test

```text

Connection Test - SCOTT - 92

		
./sqlrun.pl \
	--exe-mode sequential \
	--connect-mode flood \
	--tx-behavior rollback \
	--max-sessions 3 \
	--exe-delay 0.1 \
	--db p1 \
	--username scott \
	--password tiger \
	--parmfile parameters.conf \
	--sqlfile sqlfile.conf  \
	--runtime 60 

SQL PARSER:

DEBUG: 0
sqlParmFileFQN:  SQL/sqlfile.conf
exeMode: sequential

Connect Mode: flood
PID: 19960
Waiting on child 19960...
PID: 0
PID: 19962
Waiting on child 19962...
DRIVER: Oracle
PID: 0
DRIVER: Oracle
PID: 19964
Waiting on child 19964...
PID: 0
DRIVER: Oracle

```

## The --context-tag option

At times you may want to run repeat tests with different parameters, and record some in-app metrics.

For example: an INSERT test which is used with a varying number of connections.

For each iteration, record the time required for each insert and commit.

To differentiate between them, the Oracle `DBMS_SESSION.SET_CONTEXT` procedure is used to set the context.

The context is retrieved via the SQL `SYS_CONTEXT()` function.

The `DBMS_SESSION.SET_CONTEXT` procedure cannot be called directly; it must be embedded in a PL/SQL package.

A simple package is included here in `create/sqlrun_context-package.sql`.

The package is created, and then the context namespace.

```sql
create or replace package sqlrun_context
is
   procedure set_context_tag (v_tag_in varchar2 );
end;
/

show error package sqlrun_context


create or replace package body sqlrun_context
is
   procedure set_context_tag (v_tag_in varchar2 )
   is
   begin
      dbms_session.set_context(namespace => 'SQLRUN', attribute => 'TAG', value => v_tag_in );
   end;
end;
/

show error package body sqlrun_context


create or replace context sqlrun using sqlrun_context;
```

To setup for the insert test use `create/create-insert-test.sql`

```sql

drop sequence sqlrun_insert_seq;
drop table sqlrn

create sequence sqlrun_insert_seq cache 10000;

create table sqlrun_insert (
	id integer,
	sql_timestamp timestamp,
	tag varchar2(32),
	response_time_insert integer,
	response_time_commit integer
)
/

create unique index sqlrun_insert_u_idx on sqlrun_insert(id);
```

Following is the code from `SQL\insert-test.sql` that is used to perform the tests:

```sql
declare
   xid integer;
   t1 timestamp;
   t2 timestamp;
   t3 timestamp;
   tdiff1 number;
   tdiff2 number;
begin
   t1 := systimestamp;

   xid := sqlrun_insert_seq.nextval;

   insert into sqlrun_insert(id,sql_timestamp,tag)
   values(xid, t1, sys_context('SQLRUN','TAG'));

   t2 := systimestamp;

   tdiff1 := extract(second from (t2 - t1));

   commit;

   t3 := systimestamp;

   tdiff2 := extract(second from (t3 - t2));

   update sqlrun_insert
   set
      response_time_insert = tdiff1 * 1000000,
      response_time_commit = tdiff2 * 1000000
   where id = xid;

   commit;

end;
```

Now to use it:

### sqlfile.conf

```text
$ grep -Ev '^(\s*$|#)' SQL/sqlfile.conf
,
1,insert-test.sql,
```

### sqlrun-context.sh

```bash
#!/bin/bash		

sessions=10
runtime=20


./sqlrun.pl \
	--exe-mode sequential \
	--connect-mode trickle \
	--connect-delay 0.1 \
	--context-tag "SQLRUN-${sessions}" \
	--tx-behavior rollback \
	--max-sessions $sessions \
	--exe-delay 0.1 \
	--db o77-swingbench02/soe \
	--username soe \
	--password soe \
	--parmfile parameters.conf \
	--sqlfile sqlfile.conf  \
	--runtime $runtime 
```

Now to run it:

```text
$ ./sqlrun-context.sh
Connection Test - SOE - 48


SQL PARSER:

DEBUG: 0
sqlParmFileFQN:  SQL/sqlfile.conf
exeMode: sequential

Connect Mode: trickle
PID: 31109
Waiting on child 31109...
PID: 0
Waiting 100000 microseconds for new connection
DRIVER: Oracle
Timer Check: 20
PID: 31111
Waiting on child 31111...
PID: 0
Waiting 100000 microseconds for new connection
DRIVER: Oracle
Timer Check: 20
PID: 31113
Waiting on child 31113...
PID: 0
Waiting 100000 microseconds for new connection
DRIVER: Oracle
Timer Check: 20
PID: 31115
Waiting on child 31115...
PID: 0
Waiting 100000 microseconds for new connection
DRIVER: Oracle
Timer Check: 20
PID: 31118
Waiting on child 31118...
PID: 0
Waiting 100000 microseconds for new connection
DRIVER: Oracle
Timer Check: 20
PID: 31120
Waiting on child 31120...
PID: 0
Waiting 100000 microseconds for new connection
DRIVER: Oracle
Timer Check: 20
PID: 31122
Waiting on child 31122...
PID: 0
Waiting 100000 microseconds for new connection
DRIVER: Oracle
Timer Check: 20
PID: 31124
Waiting on child 31124...
PID: 0
Waiting 100000 microseconds for new connection
DRIVER: Oracle
Timer Check: 20
PID: 31126
Waiting on child 31126...
PID: 0
Waiting 100000 microseconds for new connection
DRIVER: Oracle
Timer Check: 20
PID: 31128
Waiting on child 31128...
PID: 0
Waiting 100000 microseconds for new connection
DRIVER: Oracle
Timer Check: 19

```

Check the number of rows created:

```

SQL> select count(*) from sqlrun_insert where tag  = 'SQLRUN-10-20';

  COUNT(*)
----------
      1836
```

### Display the results of several insert tests

Test environment:

Oracle Server: 19.3

#### SGA

```text

large pool           33,554,432
shared pool         545,656,680
streams pool         67,108,864
                  9,093,250,120
               ----------------
sum               9,739,570,096

4 rows selected.

Database Buffers        9,059,696,640          0
Fixed Size                  9,149,512          0
Redo Buffers               24,403,968          0
Variable Size           1,644,167,168          0
                     ----------------
sum                    10,737,417,288

4 rows selected.
```

Server: Oracle Linux 7.7

#### Memory

```text
# free
              total        used        free      shared  buff/cache   available
Mem:       16151276    11872760     1632092       87692     2646424     4005920
Swap:       8257532        1292     8256240
```

#### CPU (VirtualBox)

```text
# lscpu
Architecture:          x86_64
CPU op-mode(s):        32-bit, 64-bit
Byte Order:            Little Endian
CPU(s):                3
On-line CPU(s) list:   0-2
Thread(s) per core:    1
Core(s) per socket:    3
Socket(s):             1
NUMA node(s):          1
Vendor ID:             GenuineIntel
CPU family:            6
Model:                 60
Model name:            Intel(R) Core(TM) i5-4590 CPU @ 3.30GHz
Stepping:              3
CPU MHz:               3292.450
BogoMIPS:              6584.90
Hypervisor vendor:     KVM
Virtualization type:   full
L1d cache:             32K
L1i cache:             32K
L2 cache:              256K
L3 cache:              6144K
NUMA node0 CPU(s):     0-2
Flags:                 fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx rdtscp lm constant_tsc rep_good nopl xtopology nonstop_tsc cpuid tsc_known_freq pni pclmulqdq ssse3 cx16 pcid sse4_1 sse4_2 x2apic movbe popcnt aes xsave avx rdrand hypervisor lahf_lm abm invpcid_single pti fsgsbase avx2 invpcid md_clear flush_l1d
```

### Tests

Use the `xaction-sql/count.sql` script for a report of several such tests:

Performed with these scripts as needed

* sqlrun.sh
* sqlrun-dcrp.sh
* sqlrun-drcp-base.sh

TAG format:

* Pooled Connection Tests
** TESTNAME-SessionCount-ConnectPoolServers

* Direct Connection Tests
** TESTNAME-SessionCount

```text

SQL> @count
                                    MIN         MAX         AVG         MED         MIN         MAX         AVG         MED
                                 INSERT      INSERT      INSERT      INSERT      COMMIT      COMMIT      COMMIT      COMMIT
TAG                ROWCOUNT        TIME        TIME        TIME        TIME        TIME        TIME        TIME        TIME         SLA
---------------- ---------- ----------- ----------- ----------- ----------- ----------- ----------- ----------- ----------- -----------
DRCP-256-16           35523          80   1,040,166         680         133          37       2,626          80          63         760
DRCP-256-256         239873          79   3,573,747     114,188       1,876          34     314,631         212          57     114,400
DRCP-256-32           67753          79   1,148,600       2,192         131          38       5,695          98          65       2,290
DRCP-256-64          117132          83   2,099,055      14,279         133          37      10,534         114          62      14,393
DRCP-256-8            18011          81      67,663         234         148          39       1,679          84          71         318
DRCP-256-BASE        217100          79   2,991,588     139,260       2,444          35      43,742         196          60     139,456
RELAY-1024-448       320455          77   4,238,191     139,570         204          35     173,853         469          60     140,039
RELAY-1536-448       321058          79   3,137,552     146,177         179          34      91,210         322          61     146,499
RELAY-2048-448       321817          78   2,496,506     136,718         168          35      82,575         278          59     136,996
RELAY-256-16          35362          81      37,937         203         150          41       4,098          96          76         299
RELAY-256-32          68471          78      42,507         211         147          37       4,813          93          71         304
RELAY-256-64         129919          83   1,043,754       1,653         146          38       9,268          97          70       1,750
RELAY-256-8           18112          87     103,436         210         158          40       1,639          95          81         305
RELAY-512-128        199803          76   1,132,032      19,987         118          33      43,671         106          59      20,093
RELAY-64-3             6424         218      15,954         406         360          89       2,275         153         142         559
RELAY-64-32           67997          76      41,452         206         132          37      10,730          87          68         294
RELAY-64-64          122556          74   1,073,245       2,878         122          36      12,356          95          64       2,973
RELAY-768-448        331437          80   3,302,951     136,596         178          35     115,605         281          60     136,878
SQLRUN-10-20           1836          85      52,579         239         147          40       1,022          87          68         326
SQLRUN-128           178940          80   2,104,835      37,181         126          36      23,361         128          60      37,309
SQLRUN-192           216230          77   3,028,858      66,159         144          35      43,464         159          59      66,318
SQLRUN-256           197768          78   3,150,205     151,783       4,160          33      82,740         196          56     151,980
SQLRUN-320           245693          76   3,171,210     141,918         269          33      57,074         185          59     142,103
SQLRUN-384           289084          77   4,266,779     137,422       5,387          34      68,429         243          58     137,664
SQLRUN-448           360245          78   2,269,626     105,449         735          35     110,379         363          59     105,812
SQLRUN-512           300970          77   3,264,143     190,392      14,460          34     256,967         579          57     190,971
SQLRUN-64            121042          74   1,123,331       5,587         115          36      12,346          96          61       5,682
SQLRUN-640           308212          78   3,732,019     244,686      33,078          35     263,859       1,040          57     245,726

28 rows selected.

```

## Privileges Required

* execute on dbms_workload_repository
* select on dba_hist_baseline

## SQL Relay

SQL Relay is a SQL Connection pool that works with many databases.

It also works with the Perl DBI driver.

[http://sqlrelay.sourceforge.net/](http://sqlrelay.sourceforge.net/)

[https://github.com/davidwed/sqlrelay](https://github.com/davidwed/sqlrelay)




