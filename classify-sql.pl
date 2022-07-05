#!/usr/bin/env perl
#
# Jared Still
# 2017-01-24
# jkstill@gmail.com
# still@pythian.com
#
# this is a script for testing SQL Classification in lib/Sqlrun/File.pm

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

my $homedir = bsd_glob('~', GLOB_TILDE | GLOB_ERR);
if (GLOB_ERROR) {
   print "error\n";
}

my $sqlDir="$homedir/.config/sqlrun/SQL";

my $sqlFile='';
my $parmFile='';
my $bindArraySize=1;
my $cacheArraySize=100;
my $runtime=60;
my $debug=0;
my $timerTest=0;
my $schema='';
my $trace=0;
my $driver='Oracle';
my $exitHere=0;
my $driverConfigFile = '';


Getopt::Long::GetOptions(
	\%optctl, 
	"driver=s" => \$driver, # default is oracle
	"db=s" => \$db,
	"username=s" => \$username,
	"password=s" => \$password,
	"driver-config-file=s" => \$driverConfigFile,
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
	"exit-trigger!" => \$exitHere,
	"sysdba!",
	"sysoper!",
	"z!" => \$help,
	"h!" => \$help,
	"help!" => \$help
);

# set unless already set from the command line
$driverConfigFile = "$sqlDir/$driver/driver-config.json" unless $driverConfigFile;
$sqlFile="$sqlDir/$driver/sqlfile.conf" unless $sqlFile;
$parmFile="$sqlDir/$driver/parameters.conf" unless $parmFile;


-r $driverConfigFile ||  die "could not read $driverConfigFile - $!\n";
-r $sqlFile ||  die "could not read $sqlFile - $!\n";
-r $parmFile ||  die "could not read $parmFile - $!\n";

print "driver config file: $driverConfigFile\n";


my($dbConnectionMode);

# validate some arguments
my $test = $exeMode =~ m/^(sequential|semi-random|truly-random)$/;
die "The value '$exeMode' is invalid for --exe-mode\n" unless $test;

$test = $connectMode =~ m/^(trickle|flood|tsunami)$/;
die "The value '$connectMode' is invalid for --connect-mode\n" unless $test;


$dbConnectionMode = 0;
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

my $dbh = DBI->connect(
	'dbi:Oracle:' . $db, 
	$username, $password, 
	{ 
		RaiseError => 1, 
		AutoCommit => 0,
		ora_session_mode => $dbConnectionMode
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
	FQN =>  "$sqlFile",
	TYPE => 'sql',
	SQLDIR => "$sqlDir/$driver",
	HASH => \%sqlParms,
	SQL => \@sql,
	BINDS => \%binds,
	EXEMODE => $exeMode,
	DEBUG => $debug,
);

$sqlParser->parse;

undef $sqlParser;

#exit;

print "SQL " , Dumper(\@sql);

foreach my $el ( 0..$#sql ) {
	my $sqlAry = $sql[$el];
	foreach my $key ( keys %{$sqlAry} ) {
		print "key: $key\n";
		print "Type: $sqlAry->{$key}[SQL_TYPE_EL]\n";
		print "SQL: $sqlAry->{$key}[SQL_TEXT_EL]\n";
		print '=' x 80 ,"\n";
	}
}

#print "Binds: " , Dumper(\%binds);
#print "SQL Parms: " , Dumper(\%sqlParms);


