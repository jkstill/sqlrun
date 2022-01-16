#!/usr/bin/env perl

use strict;
use warnings;
# part of Perl core as of 5.14.0
# 2.273 required as 2.271 does not work here
# do not know about 2.272
use JSON::PP 2.273 ; 
use Data::Dumper;
use DBI;

use 5.14.0;

# simulate setup in sqlrun.pl
my $driver='Oracle';
my $host='';
my $dsn='';
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
$driverConfigFile = 'driver-config.json';

# for postgres
$driver='Pg';
$host='ubuntu-20-pg02';
$port=5432;
$db='postgres';
$username='benchmark';
$password='grok';


# this should match exactly to all possible keys in driver-config.json
my %connectSetup = (
	'connectParms' => {
		'db' => $db,
		'username' => $username,
		'password' => $password,
		'dsn' => $dsn,
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
	'dsn' => ''
);

my $connection = new ParseDB (
	{
		DRIVER => \$driver, 
		SETUP => \%connectSetup,
		DRIVERCONFIGFILE => \$driverConfigFile,
	}
);


#print 'main::Connect: ' . Dumper($connection);
my $dbh = $connection->connect;

# oracle
my $sql = "select 'this is oracle' from dual";
# postgres
$sql = "select 'this is PostgreSQL'";
my $sth = $dbh->prepare($sql);
$sth->execute;
my @ary = $sth->fetchrow_array;
print "test: $ary[0]\n";

$sth->finish;
$dbh->disconnect;

#print Dumper(\%connectSetup) . "\n";

package ParseDB;

use JSON::PP;
use Data::Dumper;
use IO::File;

sub new {
	my $pkg = shift;
	my $class = ref($pkg) || $pkg;
	
	my $args = shift;
	my $driver =  ${$args->{DRIVER}};

	my $driverConfigFile = ${$args->{DRIVERCONFIGFILE}};

	my %setup = %{($args->{SETUP})};

	# rewriting the arges here makes them easier to reference in methods
	my %newArgs = (
		DRIVER => $driver,
		DRIVERCONFIGFILE => $driverConfigFile,
		SETUP => \%setup
	);

	return bless \%newArgs, $class;

}

sub parseJSON {

	my $pkg = shift;
	my $class = ref($pkg) || $pkg;
	#print "parseJSON pkg: " . Dumper($pkg) . "\n"; 

	my $driver = $pkg->{'DRIVER'};
	my $driverConfigFile = $pkg->{'DRIVERCONFIGFILE'};
	my %args=%{$pkg->{SETUP}};

	#print "parseJSON Driver: $driver\n"; 
	#print 'parseJSON %args: ' . Dumper(\%args);

	my %connectSetup =%{$pkg->{'SETUP'}};

	my $fh = IO::File->new;

	$fh->open($driverConfigFile,'<') or die "could not open driver-config.json! - $!\n";
	#$fh->open('driver-config.json','<') or die "could not open driver-config.json! - $!\n";

	our $unslurp=$/;
	undef $/; # slurp mode for file read

	my $jsonTxt=<$fh>;
	$fh->close;

	$/ = $unslurp;

	my $jsonOut;

	my $ppJSON = JSON::PP->new;

	my %dbhInfo = %{%{$ppJSON->decode($jsonTxt)}{$driver}};;

	#print 'parseJSON %dbhInfo: ' . Dumper(\%dbhInfo);

	my @connectParms = @{$dbhInfo{connectParms}};
	my @dbhAttributes = @{$dbhInfo{dbhAttributes}};
	my $connectCode = $dbhInfo{connectCode};

	#print 'parseJSON Connection Parameters: ' . join(' , ',@connectParms) . "\n";
	#print 'parseJSON dbh Attributes: ' . join(' , ',@dbhAttributes) . "\n";
	#print "parseJSON Connect Code: $connectCode\n";

	print "\n";

	if ( !defined($dbhInfo{connectCode})) {
		die "connectCode not found in JSON config file\n";
	}

	if ( !defined($dbhInfo{dsn})) {
		die "dsn not found in JSON config file - required, even if blank\n";
	}

	$connectSetup{connectCode} = $dbhInfo{connectCode};
	$connectSetup{dsn} = $dbhInfo{dsn};

	foreach my $key ( keys %dbhInfo ) {
		#print "key: $key\n";

		# determine datatype
		my $ref = $dbhInfo{$key};
		my $refType = ref( $dbhInfo{$key});
		# if not a ref to hash or array, $refType will be an empty string
		# this will pick up scalars
		$refType = ref(\$ref) unless $refType; 

		#print "ref type:  $refType \n\n";
	
		# should be only ARRAR or SCALAR in the JSON config file
		if ($refType eq 'ARRAY') {
			# walk through the array
			my @ary = @{$dbhInfo{$key}};
			#print "working on key: $key\n";
			foreach my $el ( @ary ) {

				#print "   $el\n";
				#my $elName = $connectSetup{$dbhInfo}{$key}}; # array name

				if ($key eq 'connectParms' ) {

					# validate
					if (! defined( $connectSetup{connectParms}->{$el} ) ) {
						die "$el not defined in 'connectSetup{connectParms}' \n";
					};

					$connectSetup{connectCode} =~ s/<$el>/'$connectSetup{connectParms}->{$el}'/g;

				} elsif ($key eq 'dbhAttributes' ) {
					#
					# validate
					if (! defined( $connectSetup{dbhAttributes}->{$el} ) ) {
						die "$el not defined in 'connectSetup{dbhAttributes}' \n";
					};


					my $test =  $connectSetup{dbhAttributes}->{$el};
					eval { 
						use warnings 'FATAL' => 'numeric'; # fatalize the numeric warning
						my $t = $test + 1 ;
						$connectSetup{connectCode} =~ s/<$el>/$connectSetup{dbhAttributes}->{$el}/g;

					} or do {
						#print "\n\nsetting string\n\n";
						my $attr = $connectSetup{dbhAttributes}->{$el};
						$attr = "''" unless $attr;
						$connectSetup{connectCode} =~ s/<$el>/$attr}/g;
					};
					#print "\n";

				} else {
					die "invalid key name in JSON\n";
				};
			}

		} elsif ($refType eq 'SCALAR') {
			# the scalars of connectCode and dsn are set before this loop
			# nothing to do here at this time
			#print "working on $key\n";
			#print "$dbhInfo{$key}\n";
			#print "\n";
			#$connectSetup{$key} = $dbhInfo{$key};
		} else {
			# crash
			die "unsupported type found in JSON config file - '$refType' \n";
		}

	}
	
	return %connectSetup;
}


sub connect {
	my $pkg = shift;
	my $class = ref($pkg) || $pkg;

	my $driver = $pkg->{'DRIVER'};
	my $driverConfigFile = $pkg->{'DRIVERCONFIGFILE'};
	my %args=%{$pkg->{SETUP}};

	#print "connect Driver: $driver\n"; 
	#print "connect JSON file: $driverConfigFile\n"; 
	#print 'connect %args: ' . Dumper(\%args);
	my %connectSetup = $pkg->parseJSON();

	#print Dumper(\%connectSetup);
	my $connectString =  $connectSetup{connectCode};
	#print "connectString: $connectString\n";

	my $dbh;
	# this eval works 
	#$dbh=DBI->connect(eval "$connectString");

	# this also works - no quotes
	$dbh=DBI->connect(eval $connectString);

	die "could not connect - $!\n" unless $dbh;

	return $dbh;

}
;

