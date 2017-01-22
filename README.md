<h3>sqlrun</h3>

Currently an idea to create a script that can be used to run multiple SQL statements from a number of sessions.

First task is to write the help section

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

--bind-array-size  defines how many records from the bind array file are to be used per SQL execution
                   default is 1

--cache-array-size defines the size of array to use to retreive data - similar to 'set array' in sqlplus 
                   default is 100

--sysdba           connect as sysdba
--sysoper          connect as sysoper
--schema           do 'alter session set current_schema' to this schema
                   useful when you need to connect as sysdba and do not wish to modify SQL to fully qualify object names


ToDo after initial script works as intended:

- ensure login via wallet works
- store password in encrypted file (if no wallet avaiable)
- possibly allow PL/SQL - not in scope right now



</pre>

