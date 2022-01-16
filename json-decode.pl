#!/usr/bin/env perl
#


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
my $port='';
my $options='';
my $db='js01';
my $username='scott';
my $password='tiger';
my $oraSessionMode = '';
my $raiseError=1;
my $printError=0;
my $autoCommit=0;

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

our $unslurp=$/;
undef $/; # slurp mode for file read

my $jsonTxt=<>;

$/ = $unslurp;

my $jsonOut;

my $ppJSON = JSON::PP->new;
#$jsonOut = $ppJSON->pretty->encode($ppJSON->decode($jsonTxt));
#print Dumper($ppJSON->decode($jsonTxt));
# get just the parameters for this driver - nested hash

my %dbhInfo = %{%{$ppJSON->decode($jsonTxt)}{$driver}};;

print Dumper(\%dbhInfo);

my @connectParms = @{$dbhInfo{connectParms}};
my @dbhAttributes = @{$dbhInfo{dbhAttributes}};
my $connectCode = $dbhInfo{connectCode};

print 'Connection Parameters: ' . join(' , ',@connectParms) . "\n";
print 'dbh Attributes: ' . join(' , ',@dbhAttributes) . "\n";
print "Connect Code: $connectCode\n";

print "\n";

if ( !defined($dbhInfo{connectCode})) {
	die "connectCode not found in JSON config file\n";
}

$connectSetup{connectCode} = $dbhInfo{connectCode};

#print Dumper(\%connectSetup) . "\n";

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


				#print "   setting dbhAttribute: $key->$el\n";
				#print "   to: $connectSetup{dbhAttributes}->{$el}\n";
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
		#print "\n\n";

		# database handle connect parameter
		#my $tmp = $connectSetup{connectCode};
		#$tmp =~ s/<$key>/$connectSetup{$key}

		# database handle attributes
		


	} elsif ($refType eq 'SCALAR') {
		# the scalars of connectCode is set before this loop
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

#print Dumper(\%connectSetup);
my $connectString =  $connectSetup{connectCode};
print "connectString: $connectString\n";

my $dbh;
# this eval works 
#$dbh=DBI->connect(eval "$connectString");

# this also works - no quotes
$dbh=DBI->connect(eval $connectString);

die "could not connect - $!\n" unless $dbh;

# oracle
#my $sql = "select to_char(sysdate,'yyyy-mm-dd hh24:mi:ss')  from dual";

#postgresql
my $sql = "select current_date";

my $sth = $dbh->prepare($sql);
$sth->execute;
my @ary=$sth->fetchrow_array;

print "currdate: $ary[0]\n";

$sth->finish;
$dbh->disconnect;



