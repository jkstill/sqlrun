#!/usr/bin/env perl
#
# Jared Still
# 2017-01-24
# jkstill@gmail.com
# still@pythian.com

use strict;
use FileHandle;
use IO::File;
use Data::Dumper;
use DBI;
use Time::HiRes qw(usleep);
use File::Glob ':bsd_glob';

use lib 'lib';
use Sqlrun;
use Sqlrun::Timer;
use Sqlrun::File;
use Sqlrun::Connect;

use Getopt::Long;

my %optctl = ();

my $db = 'orcl';
my $help=0;
my $username = 'scott';
my $password;
my $maxSessions=2;
my $exeDelay=0.1; # seconds
my $connectDelay=0.25;
my $connectMode='flood';
my $exeMode='sequential';
my $bindArraySize=1;
my $cacheArraySize=100;
my $runtime=60;
my $debug=0;
my $timerTest=0;
my $schema='';
my $trace=0;
my $clientResultCacheTrace=0;
my $exitHere=0;
my $driver='Oracle';
my $txBehavior='rollback';
my $txTallyCount=0;  # or or 1
my $txTallyCountFile='rc.log';  # or or 1
my $pauseAtExit=0;
my $verbose=0;

my $dbConnectionMode = 0;
my $raiseError=1;
my $printError=0;
my $autoCommit=0;

my $homedir = bsd_glob('~', GLOB_TILDE | GLOB_ERR);
if (GLOB_ERROR) {
 	print "error\n";
}

my $sqlDir="$homedir/.config/sqlrun/SQL";
my $driverConfigFile = '';
my $sqlFile='';
my $parmFile='';
my $traceFileID='SQLRUN';


# postgresql and mysql
my $host='';
my $options=''; # not yet implemented
my $port='';

Getopt::Long::GetOptions(
	\%optctl, 
	"driver=s" => \$driver, # default is oracle
	"host=s" => \$host, # for postgresql
	"port=i" => \$port, # for postgresql
	"db=s" => \$db,
	"username=s" => \$username,
	"password=s" => \$password,
	"driver-config-file=s" => \$driverConfigFile,
	"raise-error=i" => \$raiseError,
	"print-error=i" => \$printError,
	"autocommit=i" => \$autoCommit,
	"tx-behavior=s" => \$txBehavior,
	"max-sessions=i" => \$maxSessions,
	"exe-delay=f" => \$exeDelay,
	"connect-delay=f" => \$connectDelay,
	"connect-mode=s" => \$connectMode,
	"exe-mode=s" => \$exeMode,
	"sqldir=s" => \$sqlDir,
	"sqlfile=s" => \$sqlFile,
	"parmfile=s" => \$parmFile,
   "runtime=i" => \$runtime,
	"bind-array-size=i" => \$bindArraySize,
	"cache-array-size=i" => \$cacheArraySize,
	"schema=s" => \$schema,
	"timer-test!" => \$timerTest,
	"debug!" => \$debug,
	"trace!" => \$trace,
	"tracefile-id=s" => \$traceFileID,
	"client-result-cache-trace!" => \$clientResultCacheTrace,
	"xact-tally!" => \$txTallyCount,
	"xact-tally-file=s" => \$txTallyCountFile,
	"pause-at-exit!" => \$pauseAtExit,
	"exit-trigger!" => \$exitHere,
	"verbose!" => \$verbose,
	"sysdba!",
	"sysoper!",
	"z!" => \$help,
	"h!" => \$help,
	"help!" => \$help
);

usage(0) if $help;

# set unless already set from the command line
$driverConfigFile = "$sqlDir/$driver/driver-config.json" unless $driverConfigFile;
$sqlFile="$sqlDir/$driver/sqlfile.conf" unless $sqlFile;
$parmFile="$sqlDir/$driver/parameters.conf" unless $parmFile;

-r $driverConfigFile ||  die "could not read $driverConfigFile - $!\n";
-r $sqlFile ||  die "could not read $sqlFile - $!\n";
-r $parmFile ||  die "could not read $parmFile - $!\n";

print "driver config file: $driverConfigFile\n" if $verbose;

# validate some arguments
my $test = $exeMode =~ m/^(sequential|semi-random|truly-random)$/;
die "The value '$exeMode' is invalid for --exe-mode\n" unless $test;

$test = $connectMode =~ m/^(trickle|flood|tsunami)$/;
die "The value '$connectMode' is invalid for --connect-mode\n" unless $test;

if ( $optctl{sysoper} ) { $dbConnectionMode = 4 }
if ( $optctl{sysdba} ) { $dbConnectionMode = 2 }

if ( ! defined($db) ) {
	usage(1);
}
#$db=$optctl{database};

if ( ! defined($username) ) {
	usage(2);
}

#$username=$optctl{username};
#$password = $optctl{password};

#print "USERNAME: $username\n";
#print "DATABASE: $db\n";
#print "PASSWORD: $password\n";
#exit;

#print "Driver: $driver\n";
#exit;

# this should match exactly to all possible keys in driver-config.json
my %connectSetup = (
	'connectParms' => {
		'db' => $db,
		'username' => $username,
		'password' => $password,
		'port' => $port,
		'host' => $host,
		'options' => $options
	},

	'dbhAttributes' => {
		'RaiseError' => $raiseError,
		'PrintError' => $printError,
		'AutoCommit' => $autoCommit,
		'ora_session_mode' => $dbConnectionMode,
	},
	# these will be populated from the config file
	'connectCode' => '',
);

my $connection = new Sqlrun::Connect (
		DRIVER => $driver, 
		SETUP => \%connectSetup,
		DRIVERCONFIGFILE => $driverConfigFile,
);


# verify timer working
if ($timerTest & $debug) {
	print "Timer Test\n" if $verbose;
	my $timer = new Sqlrun::Timer( { DURATION => 5 , DEBUG => $debug} );
	while ((my $secondsLeft = $timer->check) > 0) {
		print "$secondsLeft\n" if $verbose;
		sleep 1;
	}
}

# open the files and buffer contents
#

my %sqlParms=();
my @sql=();
my %binds=();
my %parameters=();

my $parmParser = new Sqlrun::File (
	FQN =>  "${parmFile}",
	TYPE => 'parameters',
	HASH => \%parameters,
	DEBUG => $debug,
);

$parmParser->parse;

undef $parmParser;
print "Parameters: " , Dumper(\%parameters) if $debug;

print "sqlFile: $sqlFile\n" if $verbose;

my $sqlParser = new Sqlrun::File (
	FQN =>  "${sqlFile}",
	TYPE => 'sql',
	SQLDIR => "$sqlDir/$driver",
	HASH => \%sqlParms,
	SQL => \@sql,
	BINDS => \%binds,
	EXEMODE => $exeMode,
	DEBUG => $debug,
);

$sqlParser->parse;

if ($exitHere) {
	print "Exiting...\n";
	exit;
}

undef $sqlParser;

if ($debug) {
	print "SQL " , Dumper(\@sql);
	print "Binds: " , Dumper(\%binds);
	print "SQL Parms: " , Dumper(\%sqlParms);
}


#exit;

my $timer = new Sqlrun::Timer( { DURATION => $runtime , DEBUG => $debug} );

my $sqlrun = new Sqlrun  (
	DB => $db,
	DRIVER => $driver, # defaults to Oracle if not set
	SETUP => \%connectSetup, # required for child connections
	DRIVERCONFIGFILE => $driverConfigFile, # required for child connections
	HOST => $host,
	PORT => $port,
	TXBEHAVIOR => $txBehavior, # defaults rollback
	USERNAME => $username,
	PASSWORD => $password,
	SCHEMA => $schema,
	ROWCACHESIZE => $cacheArraySize,
	BINDARRAYSIZE => $bindArraySize,
	CONNECTMODE => $connectMode,
	DBCONNECTIONMODE => $dbConnectionMode,
	TRACEFILEID => $traceFileID,
	EXEDELAY => $exeDelay,
	EXEMODE => $exeMode,
	TIMER => \$timer,
	PARAMETERS => \%parameters,
	BINDS => \%binds,
	SQLPARMS => \%sqlParms,
	SQL => \@sql,
	TRACE => $trace,
	CLIENTRESULTCACHETRACE => $clientResultCacheTrace,
	TXTALLYCOUNT => $txTallyCount,
	TXTALLTCOUNTFILE => $txTallyCountFile,
	PAUSEATEXIT => $pauseAtExit,
	VERBOSE => $verbose,
);


if ($exitHere) {
	print "Exiting due to --exit-trigger ...\n";
	print "$sqlrun->{TXBEHAVIOR}\n";
	exit;
}

if ($connectMode eq 'tsunami') {
	$sqlrun->hold();
}

print "Connect Mode: $connectMode\n" if $verbose;

$sqlrun->{DEBUG} = $debug;

print 'sqlrun: ' . Dumper($sqlrun) if $debug;

#exit;

if ($pauseAtExit) {
	print "main: $maxSessions\n" if $verbose;
	Sqlrun::pauseSetSessionCount($maxSessions);
}

for (my $i=0;$i<$maxSessions;$i++) {
	$sqlrun->child;
	if ($connectMode eq 'trickle') { 
		print "Waiting " , 10**6 * $connectDelay , " microseconds for new connection\n";
		usleep(10**6 * $connectDelay )
	}
}

# let my children go
if ($connectMode eq 'tsunami') {
	#sleep 5;
	print "Releasing Lock file\n";
	$sqlrun->release();
};

if ($pauseAtExit) {
	while (Sqlrun::pauseCheckSessionCount()) {
		print 'SessCount: ' . Sqlrun::pauseCheckSessionCount() . "\n" if $verbose;
		usleep(1e6);
	}

	print "\nSessions will exit when you press <ENTER>\n";
	my $release = <STDIN>;
	#print "RELEASE: $release\n";

	Sqlrun::pauseRelease();
}


my $chkWait=1;
while ($chkWait > -1) {
   $chkWait=wait;
	#print "chkWait: $chkWait\n";
	usleep(250000);

}


Sqlrun::pauseLockCleanup();
Sqlrun::lockCleanup();

# ##########################################################################
# END-OF-MAIN

sub usage {
	my $exitVal = shift;
	$exitVal = 0 unless defined $exitVal;
	use File::Basename;
	my $basename = basename($0);
	print qq/

usage: $basename
/;

print q(

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

);
   exit $exitVal;
};

