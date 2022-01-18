#!/usr/bin/env perl

use strict;
use warnings;
# part of Perl core as of 5.14.0
# 2.273 required as 2.271 does not work here
# do not know about 2.272
use JSON::PP 2.273 ; 
use Data::Dumper;
use DBI;

use lib 'lib';
use Sqlrun::Connect;

use lib 'lib';
use Sqlrun;
use Sqlrun::Connect;
use Sqlrun::Timer;
use Sqlrun::File;


use 5.14.0;

# simulate setup in sqlrun.pl
my $driver='Oracle';
my $host='';
my $port='';
my $options='';
my $db='js01';
my $username='scott';
my $password='tiger';
my $oraSessionMode = '';
my $raiseError=1;
my $printError=0;
my $autoCommit=0;
my $driverConfigFile = 'SQL/driver-config.json';

# for postgres
#$driver='Pg';
#$host='ubuntu-20-pg02';
#$port=5432;
#$db='postgres';
#$username='benchmark';
#$password='grok';


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
		'ora_session_mode' => $oraSessionMode,
	},
	# these will be populated from the config file
	'connectCode' => '',
);

my $connection = new Sqlrun::Connect (
		DRIVER => $driver, 
		SETUP => \%connectSetup,
		DRIVERCONFIGFILE => $driverConfigFile,
);


#print 'main::Connect: ' . Dumper($connection);
my $dbh = $connection->connect;

# oracle
my $sql = "select 'this is oracle' from dual";
# postgres
#$sql = "select 'this is PostgreSQL'";
my $sth = $dbh->prepare($sql);
$sth->execute;
my @ary = $sth->fetchrow_array;
print "test: $ary[0]\n";

$sth->finish;
$dbh->disconnect;

print Dumper(\%connectSetup) . "\n";

