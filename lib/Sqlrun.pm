

# Jared Still
# 2017-01-24
# jkstill@gmail.com
# still@pythian.com
#
# 2017-02-10 jkstill - fixed some bugs in getNextSql()
#                      changes to allow DML and PL/SQL

######################################################

=head1 Sqlrun

Not yet documented


=cut


package Sqlrun;

use warnings;
use strict;
use DBI;
use Data::Dumper;
use File::Temp qw/ :seekable /;
use Time::HiRes qw( usleep );

require Exporter;
our @ISA= qw(Exporter);
our @EXPORT_OK = q();
our @EXPORT = qw( SQL_TYPE_EL SQL_TEXT_EL );
our $VERSION = '0.01';

use constant SQL_TYPE_EL => 0;
use constant SQL_TEXT_EL => 1;


sub setSchema($$$);
sub setParms($$$);
sub setDbTrace($$$$);

# tried to use flock() here, but cannot get it to work across processes, though it should
# could use a semaphore, but that seems overkill for this

{
	my $fname;
	my $fh; # = IO::File->new_tmpfile();


sub hold {
	$fh = new File::Temp();
	$fname = $fh->filename;
	print $fh '0';

	#print "Locking $fname\n";
	
}

sub release {
	#unless ( flock ($fh, LOCK_SH|LOCK_NB )) {
	#die "could not release lock file in Sqlrun::hold\n";
	#}
	#
	seek($fh,0,0);
	print $fh '1';
	
}

sub checkHold {
	#print "Checking for lock on $fname\n";
	seek($fh,0,0);
	my $lockByte = <$fh>;
	#print "LockByte: $lockByte\n";
	return $lockByte;
}

sub lockCleanup { undef $fh }

}

# get db name - brand, not individual name
# returns lowercase name - oracle,mysql, ??
# see DBI get_info docs
sub getDbName($) {
	my ($dbh) = @_;
	lc($dbh->get_info( 17 ));
}

#sub getNextSql($currSqlNum,$sql,$self->{EXEMODE});
sub getNextSql {
	my ($currSqlNum,$maxElement,$exeMode) = @_;

	$currSqlNum = 0 unless defined($currSqlNum);

	if ($exeMode eq 'sequential') {
		if ($currSqlNum == $maxElement) {
			return 0;
		} else { 
			$currSqlNum++;
			return $currSqlNum;
		}
	} elsif (
		$exeMode eq 'semi-random' 
		or $exeMode eq 'truly-random'
	) {
		return int(rand($maxElement+1));
	} else { die "unknown exeMode of $exeMode in Sqlrun::getNextSql\n" }

}

sub getNextBindNum {
	my ($setNum, $setMax) = @_;

	#print qq{
	#GET NEXT BIND:
	#setNum: $setNum
	#setMax: $setMax
	#};

	return 0 unless defined($setNum);
	$setNum++;
	if ($setNum < $setMax) { return $setNum }
	else { return 0}
}

# schema setter dispatch table
my %parmSetters = (
	'oracle' => \&_setOracleParms,
	'mysql' => \&_setMySQLParms, # if there is an equivalent
);

sub _setOracleParms {
	my ($dbh,$debug,$parms) = @_;
	foreach my $parameterName (keys %{$parms} ) {
		print "Parameter: $parameterName\n" if $debug;
		print "Value: $parms->{$parameterName}\n" if $debug;
		eval { 
			local $dbh->{RaiseError} = 0;
			local $dbh->{PrintError} = 1;
			$dbh->do(qq{alter session set $parameterName = '$parms->{$parameterName}'});
		};

		if ($@) {
				my($err,$errStr) = ($dbh->err, $dbh->errstr);
				warn "Error $err, $errStr encountered setting $parameterName\n";
		}
	}
};

sub _setMySQLParms {
	my ($dbh,$debug,$parms) = @_;
	return 1;
};

sub setParms($$$) {
	my ($dbh,$debug,$parms) = @_;
	$parmSetters{getDbName($dbh)}->($dbh,$debug,$parms);
}

# schema setter dispatch table
my %schemaSetters = (
	'oracle' => \&_setOracleSchema,
	'mysql' => \&_setMySQLSchema, # if there is an equivalent
);

sub _setMySQLSchema {
	my ($dbh,$debug,$schema) = @_;
	return 1; # needs code
}

sub _setOracleSchema {

	my ($dbh,$debug,$schema) = @_;

	if ($schema) {
		eval { 
			local $dbh->{RaiseError} = 0;
			local $dbh->{PrintError} = 1;
			$dbh->do(qq{alter session set current_schema = $schema});
		};

		if ($@) {
			my($err,$errStr) = ($dbh->err, $dbh->errstr);
			die "Error $err, $errStr encountered setting current_schema = $schema} \n";
		}
	}
}

sub setSchema($$$) {
	my ($dbh,$debug,$schema) = @_;
	$schemaSetters{getDbName($dbh)}->($dbh,$debug,$schema);
};


# schema setter dispatch table
my %traceSetters = (
	'oracle' => \&_setOracleTrace,
	'mysql' => \&_setMySQLTrace, # if there is an equivalent
);

sub _setOracleTrace {
	my ($dbh,$debug,$trace,$traceFileID) = @_;
	if ($trace) {

		print "CHILD TRACEFILE ID: $traceFileID\n"  if $debug;

		eval { 
			local $dbh->{RaiseError} = 0;
			local $dbh->{PrintError} = 1;
			$dbh->do(qq{alter session set tracefile_identifier='${traceFileID}'});
		};

		if ($@) {
			my($err,$errStr) = ($dbh->err, $dbh->errstr);
			die "Error $err, $errStr encountered setting tracefile_identifier = ${traceFileID} \n";
		}

		my $sql = qq{select i.host_name || ':' || d.value
from v\$instance i,
v\$diag_info d
where d.name = 'Default Trace File'};

		my $sth = $dbh->prepare($sql);
		$sth->execute;
		my ($traceFileInfo) = ($sth->fetchrow);
		$sth->finish;
		print "Trace File: $traceFileInfo\n";

		eval { 
			local $dbh->{RaiseError} = 0;
			local $dbh->{PrintError} = 1;
			$dbh->do(qq{alter session set events '10046 trace name context forever, level 12'});
		};

		if ($@) {
					 my($err,$errStr) = ($dbh->err, $dbh->errstr);
				die "Error $err, $errStr encountered setting 10046 trace on\n";
		}
	}
}

sub _setMySQLTrace {
	my ($dbh,$debug,$trace) = @_;
	return 1;
}

sub setDbTrace($$$$) {
	my ($dbh,$debug,$trace,$traceFileID) = @_;
	return unless $trace;
	$traceSetters{getDbName($dbh)}->($dbh,$debug,$trace,$traceFileID);
};

sub new {
	my $pkg = shift;
	my $class = ref($pkg) || $pkg;
	#print "Class: $class\n";
	my (%args) = @_;

	my $traceFileID='';

	$args{DRIVER} = 'Oracle' unless defined $args{DRIVER};

	# this may be useful for other than oracle
	if ($args{TRACE}) {

		# set tracefile_identifier
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);

		$year += 1900;
		$sec = sprintf("%02d",$sec);
		$min = sprintf("%02d",$min);
		$hour = sprintf("%02d",$hour);
		$wday = sprintf("%02d",$wday);
		$mon = sprintf("%02d",$mon);

		my $timestamp = qq(${year}${mon}${wday}${hour}${min}${sec});
		$traceFileID = qq(SQLRUN-${timestamp});
		print "tracefile_identifier = $traceFileID\n";

	}

	$args{TRACEFILEID} = $traceFileID;

	my $retval = bless \%args, $class;
	return $retval;
}

sub child {
	my $self = shift;

	my $debug = $self->{DEBUG};

	#if ($debug) { print "Child IS in debug mode\n" }
	#else { print "Child is NOT in debug mode\n" }

	my $pid = fork;
	print "PID: $pid\n";

	unless ($pid) {
		$pid = fork;
		unless ($pid) {
			print qq{

DOIT: 
db: $self->{DB}
username: $self->{USERNAME}
			\n} if $debug;

			print "DRIVER: $self->{DRIVER}\n";

			my $dbh = DBI->connect(
				qq(dbi:$self->{DRIVER}:) . $self->{DB},
				$self->{USERNAME},$self->{PASSWORD},
				{
					RaiseError => 1,
					AutoCommit => 0,
					ora_session_mode => $self->{DBCONNECTIONMODE},
				}
			);

			die "Connect to $self->{DATABASE} failed \n" unless $dbh;

			$dbh->{RowCacheSize} = $self->{ROWCACHESIZE};

			# seed rand for child
			srand($$);

			setParms($dbh,$self->{DEBUG},$self->{PARAMETERS});

			setSchema($dbh,$self->{DEBUG},$self->{SCHEMA});

			# sets 10046 trace in Oracle
			# code needed for other databases
			setDbTrace($dbh,$self->{DEBUG},$self->{TRACE},$self->{TRACEFILEID});

			#print "Child Self " , Dumper($self);

			# tsunami mode waits untill all connections made before executing test SQL
			if ($self->{CONNECTMODE} eq 'tsunami') {
				print "Child $$ is waiting\n";
				while (! $self->checkHold()) {
					#print "Child $$ is waiting\n";
					usleep(250000);
				}
			}

			my %handles=();
			my $sql = $self->{SQL}; # array of hash - hash is sqlfile_name => sql
			my $binds = $self->{BINDS}; # hash of arrays - sqlname,[binds]
			my %bindSetNum = ();
			my %bindSetMax = ();
			my $timer = $self->{TIMER};
			my $currSqlNum = undef;
			my %bindNum= ();

			foreach my $bindKey ( keys %{$binds} ) {
				my @bindSet = @{$binds->{$bindKey}};
				$bindSetMax{$bindKey} = $#bindSet;
				$bindSetNum{$bindKey} = 0;
			}

			print "Timer Check: ", $$timer->check(), "\n";

			while ($$timer->check() > 0 ) {

				print "Past Timer Check\n" if $debug;

# need to modify starting here
# sql and type now stored in an array
# see code at end of test script classify-sql.pl 

				print "Last El: $#{$sql}\n" if $debug;
				$currSqlNum = getNextSql($currSqlNum,$#{$sql},$self->{EXEMODE});
				print "SQL Number: $currSqlNum\n" if $debug;

				my %tmpHash = %{$sql->[$currSqlNum]};
				print 'Tmp HASH: ', Dumper(\%tmpHash) if $debug;

				# only 1 element in this hash - an array ref
				my @sqlNames = map { $_ } keys %tmpHash;
				my $sqlName = pop @sqlNames;

				print "SQL Name: $sqlName\n" if $debug;

				my $sqlType = $tmpHash{$sqlName}->[SQL_TYPE_EL];

				print "SQL TYPE: $sqlType\n" if $debug;

				unless ($handles{$sqlName})  { 
					$handles{$sqlName} = $dbh->prepare($tmpHash{$sqlName}->[SQL_TEXT_EL],{ora_check_sql => 0});
				}

				if ($binds->{$sqlName}) {
					#$bindNum = getNextBindNum($bindSetNum{$sqlName}, $bindSetMax{$sqlName});
					$bindNum{$sqlName} = getNextBindNum($bindNum{$sqlName}, $bindSetMax{$sqlName});
					my $bindSet = $binds->{$sqlName};
					if ($debug) {
						print 'BIND SET: ' , Dumper($bindSet);
						print "bind Num: $bindNum{$sqlName}\n";
						print "Bind Row: " , join(' - ', @{$bindSet->[$bindNum{$sqlName}]} ) , "\n";
					}

					$handles{$sqlName}->execute(@{$bindSet->[$bindNum{$sqlName}]});
				} else {
					$handles{$sqlName}->execute;
				}

				if ($sqlType eq 'SELECT') { 
					while( my $ary = $handles{$sqlName}->fetchrow_arrayref ) {
						#warn "RESULTS\n";
						#warn join(' - ',@{$ary}),"\n";
	
						# probably should put some logging here
					}
				}

				if ($sqlType eq 'DML') {
					if ($self->{TXBEHAVIOR} eq 'rollback') { $dbh->rollback }
					else { $dbh->commit }
				}

				usleep($self->{EXEDELAY} * 10**6);
			}

			$dbh->disconnect;

			#print Dumper($self);
			exit 0;
		}
		exit 0;
	}
	print "Waiting on child $pid...\n";
	waitpid($pid,0);

}


1;


