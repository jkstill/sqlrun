#!/usr/bin/env perl
#
use strict;
use FileHandle;
use DBI;

use Getopt::Long;

my %optctl = ();

my $db = 'orcl';
my $username = 'scott';
my $password;
my $maxSessions=2;
my $exeDelay=.1; # seconds
my $connectDelay=.25;
my $connectMode='flood';
my $exemode='sequential';
my $sqlDir='SQL';
my $sqlFile='sqlfiles.conf'
my $bindArraySize=1;
my $cacheArraySize=100;

Getopt::Long::GetOptions(
	\%optctl, 
	"db=s" => \$db,
	"username=s" => \$username,
	"password=s" => \$password,
	"max-sessions=i" => \$maxSessions,
	"exe-delay=f" => $exeDelay,
	"connect-delay=f" => $connectDelay,
	"exe-mode=s" => \$exeMode,
	"sqldir=s" => \$sqlDir,
	"sqlfile=s" => \$sqlFile ,
	"bind-array-size=i" => \$bindArraySize,
	"cache-array-size=i" => \$cacheArraySize,
	"sysdba!"s,
	"sysoper!",
	"z","h","help");

my($connectionMode);

$connectionMode = 0;
if ( $optctl{sysoper} ) { $connectionMode = 4 }
if ( $optctl{sysdba} ) { $connectionMode = 2 }

if ( ! defined($optctl{database}) ) {
	usage(1);
}
#$db=$optctl{database};

if ( ! defined($optctl{username}) ) {
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
$dbh->{RowCacheSize} = 100;

my $sql=q{select user from dual};

my $sth = $dbh->prepare($sql,{ora_check_sql => 0});

$sth->execute;

while( my $ary = $sth->fetchrow_arrayref ) {
	#print "\t\t$${ary[0]}\n";
	print "\t\t$ary->[0]\n";
}

$dbh->disconnect;

sub usage {
	my $exitVal = shift;
	$exitVal = 0 unless defined $exitVal;
	use File::Basename;
	my $basename = basename($0);
	print qq/

usage: $basename

  -database      target instance
  -username      target instance account name
  -password      target instance account password
  -sysdba        logon as sysdba
  -sysoper       logon as sysoper

  example:

  $basename -database dv07 -username scott -password tiger -sysdba 
/;
   exit $exitVal;
};



