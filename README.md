<h3>sqlrun</h3>

sqlrun.pl is a Perl script and related modules that can be used to run multiple SQL statements from a number of sessions.

<pre>

              --db  which database to connect to
        --username  account to connect to
        --password  obvious. 
                    user will be prompted for password if not on the command line

    --max-sessions  number of sessions to use
 
       --exe-delay  seconds to delay between sql executions defaults to 0.1 seconds

   --connect-delay  seconds to delay be between connections
                    valid only for '--session-mode trickle'

    --connect-mode  [ trickle | flood | tsunami ] - default is flood
                    trickle: gradually add sessions up to max-sessions
                    flood: startup sessions as quickly as possible
                    tsunami: wait until all sessions are connected before they are allowed to work

        --exe-mode  [ sequential | semi-random | truly-random ] - default is sequential
                    sequential: each session iterates through the SQL statements serially
                    semi-random: a value assigned in the sqlfile determines how frequently each SQL is executed
                    truly-random: SQL selected randomly by each session

          --sqldir  location of SQL script files and bind variable files. default is ./SQL

         --sqlfile  this refers to the file that names the SQL script files to use 
                    the names of the bind variable files will be defined here as well
						  default is ./sqlfile.conf

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

ToDo after initial script works as intended:

- ensure login via wallet works
- store password in encrypted file (if no wallet avaiable)
- possibly allow PL/SQL - not in scope right now

Currently Working on:

- classify SQL by type to allow DML and PL/SQL

</pre>

<h3>Test Run</h3>

This is using the example configuration files

<pre>


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
jkstill@poirot ~/oracle/sqlrun $

jkstill@poirot ~/oracle/sqlrun $ ps
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
</pre>

Here is another test using the --trace option

<pre>

./sqlrun.pl \
         --exe-mode semi-random \
         --connect-mode flood \
         --connect-delay 2 \
         --max-sessions 20 \
         --db p1 \
         --username sys \
         --password sl3add \
         --schema system \
         --sysdba \
         --parmfile parameters.conf \
         --sqlfile sqlfile.conf  \
         --runtime 10 \
         --trace

Connection Test - SYS - 90


SQL PARSER:

DEBUG: 0
sqlParmFileFQN:  SQL/sqlfile.conf
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

</pre>



