package Sqlrun::File;

use strict;
use IO::File;
use Data::Dumper;
require Exporter;
our @ISA= qw(Exporter);
#our @EXPORT_OK = ( 'sub-1','sub-2');
our $VERSION = '0.01';

use vars qw(%fileParsers $test);

my $test='this is a dang test';

sub _parseParms {

	my $self = shift;
	my $parmFH = new IO::File;
	my $parmFileFQN = $self->{FQN};
	$parmFH->open($parmFileFQN,'<') if -r $parmFileFQN;
	die "Cannot open $parmFileFQN \n" unless $parmFH;
	my $debug = $self->{DEBUG};

	while (<$parmFH>){
		s/^\s+//; # strip leading whitespace
		next if /^#|^$/;
		print if $debug;
		chomp;
		my @parmLine = split(/,/);
		my $parmName = shift(@parmLine);
		my $parmValue = join('',@parmLine);
		$self->{HASH}->{$parmName} = $parmValue;
	}

	$parmFH->close if $parmFH;

}

sub _parseSQL {
	my $self = shift;
	
	my $debug = $self->{DEBUG};
	my $sqlParmFileFQN = $self->{FQN};
	my $sqlParms = $self->{HASH};
	my $binds = $self->{BINDS};
	my $sqlArray = $self->{SQL};
	my $sqlDir = $self->{SQLDIR};
	my $exeMode = $self->{EXEMODE};

print qq{
 
SQL PARSER:

DEBUG: $debug
sqlParmFileFQN:  $sqlParmFileFQN
exeMode: $exeMode

};

	my $sqlParmFileFH = new IO::File;
	$sqlParmFileFH->open($sqlParmFileFQN,'<') if -r $sqlParmFileFQN;
	die "Cannot open $sqlParmFileFQN \n" unless $sqlParmFileFH;

	my $delimiter=<$sqlParmFileFH>;
	chomp $delimiter;
	$delimiter =~ s/\s+//;

	print "Delimiter: |$delimiter|\n" if $debug;

	while (<$sqlParmFileFH>){
		s/^\s+//; # strip leading whitespace
		next if /^#|^$/;
		print if $debug;
		chomp;
		my ($frequency,$sqlScript,$bindFile) = split(/${delimiter}/);
		$sqlParms->{$sqlScript} = $frequency;

print qq{

===================
sqlscript: $sqlScript
bindfile: $bindFile
frequency: $frequency

} if $debug;

		if ($bindFile) {
			my $bindFileFQN =  "${sqlDir}/${bindFile}";
			die "cannot read bind file $bindFileFQN\n" unless -r $bindFileFQN;
			my $bindFileFH = new IO::File;
			$bindFileFH->open($bindFileFQN,'<');
			while (<$bindFileFH>) {
				chomp;
				push @{$binds->{$sqlScript}}, split(/$delimiter/);
			}
			die "No bind values found - is $bindFileFQN empty?\n" unless keys %{$binds};
		}
	}

	$sqlParmFileFH->close;

	foreach my $sqlFile(keys %{$sqlParms}) {

		my $sqlFileFQN = "${sqlDir}/${sqlFile}";
		my $sqlFileFH = new IO::File;
		$sqlFileFH->open($sqlFileFQN,'<') if -r $sqlFileFQN;

		my @lines = <$sqlFileFH>;
		my $sql = join('',grep(!/^\s*$/,@lines));

		chomp $sql;
		print "SQL: $sql\n" if $debug;

		for (my $i=0;$i < ($exeMode eq 'semi-random' ? $sqlParms->{$sqlFile} : 1); $i++) {
			push @{$sqlArray}, {$sqlFile,$sql};
		}
		#if ($exeMode eq 'semi-random' ) {
		#} else {
		#}

	}
}

my %fileParsers = (
	parameters => \&_parseParms,
	sql => \&_parseSQL
);


sub new {
	my $pkg = shift;
	my $class = ref($pkg) || $pkg;
	#print "Class: $class\n";
	my (%args) = @_;
	#      #print 'args: ' , Dumper($args);
	#

	#print "args: " , Dumper($args);
	#my $self = {
	#FQN => $args->{'FQN'},
	#TYPE => $args->{'parameters'},
	#HASH => $args->{HASH},
	#};

	my $retval = bless \%args, $class;
	return $retval;
}


sub parse {
	my $self = shift;
	my $parseType = lc($self->{TYPE});
	my $debug = $self->{DEBUG};

	if ($debug) {
		print "TYPE: $parseType\n" ;
		print "Self: " , Dumper($self);
	
	}

	die "$parseType invalid for 'parse'\n" unless $fileParsers{$parseType};

	$fileParsers{$parseType}->($self);
}

1;

