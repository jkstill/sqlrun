
# Jared Still
# 2017-01-24
# jkstill@gmail.com
# still@pythian.com

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

=head1 sub classifySQL

 Classify SQL statements as one of the following

   SELECT
	DML (UPDATE/DELETE/INSERT/MERGE)
	PL/SQL

=cut 

sub classifySQL {
	my $lSql = ${$_[0]};

	# strip comments and leading space
	#print "XXXXXXXXXXXXXX Before SQL: $lSql\n";

	$lSql =~ s/^\s*--.*$//gom; # comments
	$lSql =~ s/\n/ /gosm; # newlines
	$lSql =~ s/^\s+//gosm; # leading space
	#$lSql =~ s/^$//gnr;

	# the resulting string should be begin with 
	# select
	# update
	# delete
	# insert
	# merge
	# begin
	# declare

	#print "XXXXXXXXXXXXXX After SQL: |$lSql|\n";

	my ($type) = split(/\s+/,uc($lSql));

	if ($type =~ /UPDATE|DELETE|INSERT|MERGE/ ) {
		return 'DML'
	} elsif ( $type =~ /SELECT|WITH/ ) {
		return 'SELECT'
	} elsif ( $type =~ /BEGIN|DECLARE/ ) {
		return 'PLSQL'
	} else {
		return 'UNKNOWN'
	}
	
}

=head1 sub _parseSQL

 Open and read SQL files
 classify the SQL as DML - SELECT - PL/SQL


=cut 

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

	# first get the parameters
	# this should be a separate subroutine

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
			my @tmpAry = ();
			while (<$bindFileFH>) {
				chomp;
				my $line=$_;
				print "BIND LINE: $line\n" if $debug;
				push @tmpAry, [split(/$delimiter/,$line)];
			}
			$binds->{$sqlScript} = \@tmpAry;
			#print 'TMP ARRAY: ', Dumper(\@tmpAry);
			die "No bind values found - is $bindFileFQN empty?\n" unless keys %{$binds};
		}
	}

	$sqlParmFileFH->close;

	foreach my $sqlFile(keys %{$sqlParms}) {

		my $sqlFileFQN = "${sqlDir}/${sqlFile}";
		my $sqlFileFH = new IO::File;
		$sqlFileFH->open($sqlFileFQN,'<') if -r $sqlFileFQN;

		my @lines = <$sqlFileFH>;
		my $sql = join('',grep(!/^\s*$/,@lines)); # skip blank lines

		chomp $sql;
		print "SQL: $sql\n" if $debug;

		my $sqlType = classifySQL(\$sql);

		# need to determine if SQL is SELECT, DML or PL/SQL
		# may be other types, so use dispatch tables to process
		# do not forget CTE (WITH clause)
		#

		for (my $i=0;$i < ($exeMode eq 'semi-random' ? $sqlParms->{$sqlFile} : 1); $i++) {
			push @{$sqlArray}, {$sqlFile,[$sqlType,$sql]};
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

