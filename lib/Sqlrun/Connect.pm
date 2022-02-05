
package Sqlrun::Connect;

use JSON::PP;
use Data::Dumper;
use IO::File;
#use Carp;

sub new {
	my $pkg = shift;
	my $class = ref($pkg) || $pkg;
	my (%args) = @_;
	return bless \%args, $class;
}

# pass driver name
my %connectCleanup = (
	'Oracle' => \&_OracleConnectCleanup,
	'mysql' => \&_mysqlConnectCleanup,
	'Pg' => \&_PgConnectCleanup
);

# pass connection string
sub _mysqlConnectCleanup {
	my $connectString = shift;
	$connectString =~ s/'//g ;
	return $connectString;
}

sub _OracleConnectCleanup {
	# do nothing at this time
	return shift;
}

sub _PgConnectCleanup {
	# do nothing at this time
	return shift;
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

	#$fh->open($driverConfigFile,'<') or croak "could not open $driverConfigFile! - $!\n";
	$fh->open($driverConfigFile,'<') or die "Sqlrun::Connect::parseJSON could not open driver-config file '$driverConfigFile'! - $!\n";

	our $unslurp=$/;
	undef $/; # slurp mode for file read

	my $jsonTxt=<$fh>;
	$fh->close;

	$/ = $unslurp;

	my $jsonOut;

	my $ppJSON = JSON::PP->new;

	# this works in 5.24 Perl, but not 5.16
	#my %dbhInfo = %{%{$ppJSON->decode($jsonTxt)}{$driver}};
	my $jsonInfo = $ppJSON->decode($jsonTxt);
	my %dbhInfo = %{$jsonInfo->{$driver}};


	#print 'parseJSON %dbhInfo: ' . Dumper(\%dbhInfo);

	my @dbhAttributes = @{$dbhInfo{dbhAttributes}};
	my $connectCode = $dbhInfo{connectCode};

	#print 'parseJSON dbh Attributes: ' . join(' , ',@dbhAttributes) . "\n";
	#print "parseJSON Connect Code: $connectCode\n";

	#print "\n";

	if ( !defined($dbhInfo{connectCode})) {
		die "connectCode not found in JSON config file\n";
	}

	$connectSetup{connectCode} = $dbhInfo{connectCode};

	#print 'Connect.pm %connectSetup: ' . Dumper(\%connectSetup);

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
			# the scalars of connectCode are set before this loop
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

	# any special steps per driver
	#
	
	
	return %connectSetup;
}


# using driver name
my %connectTestSQL = (
	Oracle => \&_testOracleSQL,	
	mysql => \&_testmysqlSQL,	
	Pg => \&_testPgSQL,	
);

# single parameter is db driver name: Oracle, Pg, mysql, ...
sub _testOracleSQL {
	return q{select 'Connection Test' test, user, sys_context('userenv','sid') SID from dual};
}

sub _testPgSQL {
	return q{select 'Connection Test - PostgreSQL'};
}

sub _testmysqlSQL {
	return q{select 'Connection Test - mysql'};
}

# parameters are dbh and driver name
sub testConnection {
	my $dbh = shift;
	my $driver = shift;

	my $sql = $connectTestSQL{$driver}();
	my $dbhOptions = ();

	if ($driver eq 'Oracle') {
		$dbhOptions->{ora_check_sql} = 0;
	}

	eval { 
		my $sth = $dbh->prepare($sql,$dbhOptions);
		$sth->execute;

		# test connection
		while( my $ary = $sth->fetchrow_arrayref ) {
			#warn join(' - ',@{$ary}),"\n";
		}

	};

	if ($@) {
		warn "failed to perform test query on the $driver database\n";
		warn "SQL: $sql\n";
		warn "options: " . Dumper($dbhOptions) . "\n";

		die "exiting with error\n$@\n";
	}

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

	# strip quotes from mysql connect strings - it will not work with quotes
	$connectString = $connectCleanup{$driver}->($connectString);

	my $dbh;
	# this eval works 
	#$dbh=DBI->connect(eval "$connectString");

	# this also works - no quotes
	$dbh=DBI->connect(eval $connectString);
	#$class->{DBH} = $dbh;

	die "could not connect - $!\n" unless $dbh;

	# make sure a SELECT works
	testConnection($dbh,$driver);

	return $dbh;
}
;
1;

