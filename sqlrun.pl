#!/usr/bin/env perl
#
use strict;
use FileHandle;
use IO::File;
use Data::Dumper;
use DBI;

use lib 'lib';
use Sqlrun;
use Sqlrun::Timer;
use Sqlrun::File;


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
my $sqlDir='SQL';
my $sqlFile='sqlfiles.conf';
my $parmFile='parameters.conf';
my $bindArraySize=1;
my $cacheArraySize=100;
my $runtime=60;
my $debug=0;
my $timerTest=0;

Getopt::Long::GetOptions(
	\%optctl, 
	"db=s" => \$db,
	"username=s" => \$username,
	"password=s" => \$password,
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
	"timer-test!" => \$timerTest,
	"debug!" => \$debug,
	"sysdba!",
	"sysoper!",
	"z!" => \$help,
	"h!" => \$help,
	"help!" => \$help
);

usage(0) if $help;

my($connectionMode);

# validate some arguments
my $test = $exeMode =~ m/^(sequential|semi-random|truly-random)$/;
die "The value '$exeMode' is invalid for --exe-mode\n" unless $test;

$test = $connectMode =~ m/^(trickle|flood|tsunami)$/;
die "The value '$connectMode' is invalid for --connect-mode\n" unless $test;


$connectionMode = 0;
if ( $optctl{sysoper} ) { $connectionMode = 4 }
if ( $optctl{sysdba} ) { $connectionMode = 2 }

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

my $dbh = DBI->connect(
	'dbi:Oracle:' . $db, 
	$username, $password, 
	{ 
		RaiseError => 1, 
		AutoCommit => 0,
		ora_session_mode => $connectionMode
	} 
	);

die "Connect to  $db failed \n" unless $dbh;



# apparently not a database handle attribute
# but IS a prepare handle attribute
#$dbh->{ora_check_sql} = 0;
$dbh->{RowCacheSize} = $cacheArraySize;

my $sql=q{select 'Connection Test' test, user, sys_context('userenv','sid') SID from dual};

my $sth = $dbh->prepare($sql,{ora_check_sql => 0});

$sth->execute;

# test connection
while( my $ary = $sth->fetchrow_arrayref ) {
	warn join(' - ',@{$ary}),"\n";
}


# disconnect should be part of an exit routine

$dbh->disconnect;


# verify timer working

if ($timerTest & $debug) {
	print "Timer Test\n";
	my $timer = new Sqlrun::Timer( { DURATION => 5 , DEBUG => $debug} );
	while ((my $secondsLeft = $timer->check) > 0) {
		print "$secondsLeft\n";;
		sleep 1;
	}
}

my $timer = new Sqlrun::Timer( { DURATION => $runtime , DEBUG => $debug} );

# open the files and buffer contents
#

my %sqlParms=();
my @sql=();
my %binds=();
my %parameters=();

my $parmParser = new Sqlrun::File (
	FQN =>  "${sqlDir}/${parmFile}",
	TYPE => 'parameters',
	HASH => \%parameters,
	DEBUG => $debug,
);

$parmParser->parse;

undef $parmParser;
print "Parameters: " , Dumper(\%parameters) if $debug;

my $sqlParser = new Sqlrun::File (
	FQN =>  "${sqlDir}/${sqlFile}",
	TYPE => 'sql',
	SQLDIR => $sqlDir,
	HASH => \%sqlParms,
	SQL => \@sql,
	BINDS => \%binds,
	EXEMODE => $exeMode,
	DEBUG => $debug,
);

$sqlParser->parse;

undef $sqlParser;

if ($debug) {
	print "SQL " , Dumper(\@sql);
	print "Binds: " , Dumper(\%binds);
	print "SQL Parms: " , Dumper(\%sqlParms);
}

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

print q/

             --db  which database to connect to
       --username  account to connect to
       --password  obvious. 
                   user will be prompted for password if not on the command line

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

--cache-array-size defines the size of array to use to retreive data - similar to 'set array' in sqlplus 
                   default is 100

--sysdba           connect as sysdba
--sysoper          connect as sysoper
--schema           do 'alter session set current_schema' to this schema
                   useful when you need to connect as sysdba and do not wish to modify SQL to fully qualify object names

  example:

  $basename -db dv07 -username scott -password tiger -sysdba 
/;
   exit $exitVal;
};

