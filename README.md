sqlrun
========


sqlrun.pl is a Perl script and related modules that can be used to run multiple SQL statements from a number of sessions.

```text

$ sqlrun.pl --help

boolean switches are negated with '--no'
ie. --raise-error becomed --no-raise-error

Drivers:

Several default paths include  <driver>, where <driver> is the name of the database name as per DBI
installed drivers can be listed with ./drivers.pl

		--db  which database to connect to
	    --driver  which db driver to use - default is 'Oracle'
       --tx-behavior  for DML - [rollback|commit] - default is rollback
		      commit or rollback is peformed after every DML transaction

	  --username  account to connect to
	  --password  obvious.
		      user will be prompted for password if not on the command line
	  --host      hostname of database
      --max-sessions  number of sessions to use

	 --exe-delay  seconds to delay between sql executions defaults to 0.1 seconds

     --connect-delay  seconds to delay be between connections
		      valid only for --session-mode trickle

      --connect-mode  [ trickle | flood | tsunami ] - default is flood
		      trickle: gradually add sessions up to max-sessions
		      flood: startup sessions as quickly as possible
		      tsunami: wait until all sessions are connected before they are allowed to work

	  --exe-mode  [ sequential | semi-random | truly-random ] - default is sequential
		      sequential: each session iterates through the SQL statements serially
		      semi-random: a value assigned in the sqlfile determines how frequently each SQL is executed
		      truly-random: SQL selected randomly by each session

	    --sqldir  location of SQL script files and bind variable files.
		      default is ~/.config/sqlrun/SQL/<driver>
		      override with fully qualified directory name

	   --sqlfile  this refers to the file that names the SQL script files to use
		      the names of the bind variable files will be defined here as well
		      override with fully qualified file name

	  --parmfile  file containing session parameters to set
		      default is ~/.config/sqlrun/SQL/<driver>/parameters.conf
		      override with fully qualified file name

--driver-config-file  A JSON file that describes the connect string for the database
		      default is ~/.config/sqlrun/SQL/<driver>/parameters.conf
		      Normally there is no need to edit this file
		      override with fully qualified file name

	   --runtime  how long (in seconds) the jobs should run
		      the timer starts when the first session starts

   --bind-array-size  defines how many records from the bind array file are to be used per SQL execution
		      default is 1
		      Note: not yet implemented

  --cache-array-size  defines the size of array to use to retreive data - similar to 'set array' in sqlplus
		      default is 100

       --raise-error  raise errors in DBI database connections - default is true
       --print-error  print errors in DBI database connections - default is false
	--autocommit  automatically commit transactions - default is false

	    --sysdba  connect as sysdba
	   --sysoper  connect as sysoper
	    --schema  do 'alter session set current_schema' to this schema
		      useful when you need to connect as sysdba and do not wish to modify SQL to fully qualify object names

	     --trace  enable 10046 trace with binds - sets tracefile_identifier to SQLRUN-timestamp
      --tracefile-id  set the tracefile identifier value. default is SQLRUN-timestamp.
		      a timestamp will be appended to the identifier.


	--xact-tally  count the number of executions of SQL specifed in sqlfile.conf
   --xact-tally-file  file used for xact-tally - default is 'rc.log'

		      counting the number of transactions may be useful when testing the client result cache
		      or SQL Tracing is not used

     --pause-at-exit  pause before exiting children - a prompt will appear to let the children exit

	     --debug  enables some debugging output
      --exit-trigger  used to trigger 'exit' code that may be present for debugging

	   --verbose  print some informational messages

  --client-result-cache-trace enable tracing of client result cache - event 10843

  example:

  $basename -db dv07 -username scott -password tiger -sysdba

$basename \
  --exe-mode semi-random \
  --connect-mode flood \
  --connect-delay 2 \
  --max-sessions 20 \
  --db p1 \
  --username sys \
  --password sys \
  --schema scott \
  --sysdba \
  --runtime 20

PL/SQL:

PL/SQL can be used with Oracle databases.

PL/pgSQL may work with PostgreSQL databases, but has not yet been tested.

It is up to you to include a commit or rollback as necessary within the PL/SQL as required

see examples in the SQL directory

```

ToDo after initial script works as intended:

* ensure login via wallet works
* store password in encrypted file (if no wallet avaiable)
* add --display-output flag for SELECT
* add --tx-frequency to control rate of commit or rollback
* add option to retrieve trace files automatically
* pre and post SQL - statements to run once before and after the tests
* alter session settings after login for postgresql and mysql.
**  this currently does work for oracle

```
## DML

DML statements can be used as well.
As with SELECT there is a limit of 1 statement per file.
A bind variable file may also be used.

Use the `--tx-behavior` option to control whether to commit or rollback.

## PL/SQL

PL/SQL consists of a 'begin end' block, or a 'declare begin end' block.

Bind variables may be used.

When using sqlplus, the default behavior when disconnecting from the database session is to commit any pending transactions.

This is not affected by 'SET AUTOCOMMIT OFF', as that is a transaction level control.

This behavior can be changed in sqlplus by 'SET EXITCOMMIT OFF'.

The DBD::Oracle documentation says this about disconnect and commit behavior:

    Disconnects from the Oracle database. Any uncommitted changes will be
    rolled back upon disconnection. It's good policy to always explicitly call
    commit or rollback at some point before disconnecting, rather than relying
    on the default rollback behavior.

Unfortunately, that does not seem to be the case.

When testing with PL/SQL and the `--tx-behavior rollback`, any DML performed in a PL/SQL block is always committed.

I have spent some time looking into how to change this behavior, but have not yet arrived at a solution.

If commit or rollback is needed, it should be included in the PL/SQL block.

Do not depend on `--tx-behavior [commit|rollback]` to control transaction behavior in PL/SQL blocks.


## Test Run SELECT only

This is using the example configuration file with the following lines uncommmented:

```text
$ cat ~/.config/sqlrun/SQL/Oracle/sqlfile.conf

2,sql-1.sql,
3,sql-2.sql
5,sql-3.sql,sql-3-binds.txt
2,sql-4.sql,sql-4-binds.txt
1,sql-system-1.sql,

```

The test run:

```text

./sqlrun.pl \
        --exe-mode semi-random \
        --connect-mode flood \
        --connect-delay 2 \
        --max-sessions 20 \
        --db p1 \
        --username sys \
        --password sys \
        --schema system \
        --sysdba \
        --runtime 10


Connection Test - SYS - 72

SQL PARSER:

DEBUG: 0
sqlParmFileFQN:  /home/jkstill/.config/sqlrun/SQL/Oracle/sqlfile.conf
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
         --username sys \
         --password nothere \
         --schema system \
         --sysdba \
         --runtime 10 \
         --trace

Connection Test - SYS - 90


SQL PARSER:

DEBUG: 0
sqlParmFileFQN:  /home/jkstill/.config/sqlrun/SQL/Oracle/sqlfile.conf
exeMode: semi-random

tracefile_identifier = SQLRUN-20170001123638
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


Trace File: ora12c102rac01.jks.com./u01/cdbrac/app/oracle/diag/rdbms/js122a/js122a1/trace/js122a1_ora_23607_SQLRUN-20170001123638.trc
Trace File: ora12c102rac01.jks.com./u01/cdbrac/app/oracle/diag/rdbms/js122a/js122a1/trace/js122a1_ora_23609_SQLRUN-20170001123638.trc
Trace File: ora12c102rac01.jks.com./u01/cdbrac/app/oracle/diag/rdbms/js122a/js122a1/trace/js122a1_ora_23613_SQLRUN-20170001123638.trc
Trace File: ora12c102rac01.jks.com./u01/cdbrac/app/oracle/diag/rdbms/js122a/js122a1/trace/js122a1_ora_23611_SQLRUN-20170001123638.trc
Trace File: ora12c102rac02.jks.com./u01/cdbrac/app/oracle/diag/rdbms/js122a/js122a2/trace/js122a2_ora_17059_SQLRUN-20170001123638.trc
Trace File: ora12c102rac01.jks.com./u01/cdbrac/app/oracle/diag/rdbms/js122a/js122a1/trace/js122a1_ora_23615_SQLRUN-20170001123638.trc
Trace File: ora12c102rac01.jks.com./u01/cdbrac/app/oracle/diag/rdbms/js122a/js122a1/trace/js122a1_ora_23617_SQLRUN-20170001123638.trc
Trace File: ora12c102rac01.jks.com./u01/cdbrac/app/oracle/diag/rdbms/js122a/js122a1/trace/js122a1_ora_23621_SQLRUN-20170001123638.trc
Trace File: ora12c102rac02.jks.com./u01/cdbrac/app/oracle/diag/rdbms/js122a/js122a2/trace/js122a2_ora_17061_SQLRUN-20170001123638.trc
Trace File: ora12c102rac01.jks.com./u01/cdbrac/app/oracle/diag/rdbms/js122a/js122a1/trace/js122a1_ora_23619_SQLRUN-20170001123638.trc
Trace File: ora12c102rac02.jks.com./u01/cdbrac/app/oracle/diag/rdbms/js122a/js122a2/trace/js122a2_ora_17065_SQLRUN-20170001123638.trc
Trace File: ora12c102rac02.jks.com./u01/cdbrac/app/oracle/diag/rdbms/js122a/js122a2/trace/js122a2_ora_17063_SQLRUN-20170001123638.trc
Trace File: ora12c102rac02.jks.com./u01/cdbrac/app/oracle/diag/rdbms/js122a/js122a2/trace/js122a2_ora_17067_SQLRUN-20170001123638.trc
Trace File: ora12c102rac02.jks.com./u01/cdbrac/app/oracle/diag/rdbms/js122a/js122a2/trace/js122a2_ora_17069_SQLRUN-20170001123638.trc
Trace File: ora12c102rac02.jks.com./u01/cdbrac/app/oracle/diag/rdbms/js122a/js122a2/trace/js122a2_ora_17071_SQLRUN-20170001123638.trc
Trace File: ora12c102rac02.jks.com./u01/cdbrac/app/oracle/diag/rdbms/js122a/js122a2/trace/js122a2_ora_17073_SQLRUN-20170001123638.trc
Trace File: ora12c102rac02.jks.com./u01/cdbrac/app/oracle/diag/rdbms/js122a/js122a2/trace/js122a2_ora_17075_SQLRUN-20170001123638.trc
Trace File: ora12c102rac02.jks.com./u01/cdbrac/app/oracle/diag/rdbms/js122a/js122a2/trace/js122a2_ora_17079_SQLRUN-20170001123638.trc
Trace File: ora12c102rac02.jks.com./u01/cdbrac/app/oracle/diag/rdbms/js122a/js122a2/trace/js122a2_ora_17077_SQLRUN-20170001123638.trc
Trace File: ora12c102rac02.jks.com./u01/cdbrac/app/oracle/diag/rdbms/js122a/js122a2/trace/js122a2_ora_17081_SQLRUN-20170001123638.trc

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
	--password XXX \
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

## Configuration

The config files are expected to be found at `~/.config/sqlrun/SQL/<driver>`, where `<driver>` is the name of a driver known to DBI.

Use `drivers.pl` to see installed drivers:

```text

$  ./drivers.pl
@driver_names: $VAR1 = [
          'DBM',
          'ExampleP',
          'File',
          'Gofer',
          'Oracle',
          'Pg',
          'Proxy',
          'SQLRelay',
          'SQLite',
          'Sponge',
          'mysql'
        ];
```

The name of the directory must exactly match the driver name.

```text
$  ls -1 ~/.config/sqlrun/SQL/Oracle

delete.sql
driver-config.json
insert-1.sql
insert-2.sql
merge.sql
parameters.conf
pg-select-1.sql
plsql-1.sql
plsql-2.sql
plsql-binds.sql
plsql-binds.txt
select-1.sql
select-2.sql
select-dual.sql
sql-1.sql
sql-2.sql
sql-3-binds.txt
sql-3.sql
sql-4-binds.txt
sql-4.sql
sql-system-1.sql
sqlfile.conf
update-1.sql
update-2.sql
```

Should you need multiple copies of sqlrun for different tests, then just use fully qualified pathnames for these arguments

* --sqldir
* --sqlfile
* --parmfile
* --driver-config-file

### sqlfile.conf

This file controls which SQL files are executed.

Instructions for use are in the file

### parameters.conf

Some setup commands may be run per each session if you choose via `ALTER SESSION`.

Currently this only works for Oracle.  Adding other database implementations is a future update.

### driver-config.json

This file describes what the DBI connection string looks like.

The following is the Pg (PostgreSQL) example:

```json

{
   "Pg": {
      "connectParms": ["db","username","password","host","port","options"],
      "dbhAttributes": [ "PrintError","RaiseError","AutoCommit"],
      "connectCode": "\"dbi:Pg:dbname=<db>;host=<host>;port=<port>;options=<options>\", <username>, <password>, { RaiseError => <RaiseError>, AutoCommit => <AutoCommit>, PrintError => <PrintError>}"
   }
}
```

Normally there should be no need to edit these files.

At this time, the mysql file has not been tested, so it may require editing.


