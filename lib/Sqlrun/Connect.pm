
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

	my %dbhInfo = %{%{$ppJSON->decode($jsonTxt)}{$driver}};;

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
1;

