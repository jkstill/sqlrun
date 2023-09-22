

# Jared Still
# 2017-01-24
# jkstill@gmail.com
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
use File::Temp qw/ :seekable tmpnam/;
use Time::HiRes qw( usleep );
use lib '.';
use Sqlrun::Connect;
use Fcntl qw(:flock SEEK_END);

require Exporter;
our @ISA= qw(Exporter);
our @EXPORT_OK = q();
our @EXPORT = qw( SQL_TYPE_EL SQL_TEXT_EL );
our $VERSION = '0.01';

use constant SQL_TYPE_EL => 0;
use constant SQL_TEXT_EL => 1;

my $flockSleepTime = 10_000; # microseconds
my $flockSleepIterMax = 1000; # 10 seconds total attempting to lock file


sub setSchema($$$);
sub setParms($$$);
sub setDbTrace($$$$);

# closure for hold/release
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

	sub lockCleanup { undef $fh; }

}
# end of hold/release subs

# closure for pause subs
# used with --pause-at-exit
{
	use IO::File;
	my $fname = tmpnam();
	my $fSessionCount = tmpnam();

	# create the files
	open(my $tmpFH,'>', $fname) or die "could not create \$fname: $fname - $!\n";
	close($tmpFH);
	open($tmpFH,'>', $fSessionCount) or die "could not create \$fSessionCount: $fSessionCount - $!\n";
	close($tmpFH);
	undef $tmpFH;

	sub openFH {
		my ($fhRef,$fileName) = @_;
		open $$fhRef, '+<', $fileName or return 0;;
		#print 'openFH ' . Dumper(\$fhRef);
		return 1;
	}

	sub openLockFH {
		my ($fhRef,$fileName) = @_;

		for (my $i=0; $i < $flockSleepIterMax; $i++) {

			eval {
				use warnings FATAL => 'all';
				open $$fhRef, '+<', $fileName or die;
				flock($$fhRef, LOCK_EX) or die "Cannot lock $fileName - $!\n";
			};

			if ($@) {
				usleep($flockSleepTime);
			} else {
				return 1;
			}
		}
		return 0;
	}

	sub pauseHold {
		my $fh;
		openLockFH(\$fh,$fname)  or die "pauseHold could not open $fname\n";;
		print $fh '0';
		close($fh);
		#print "pauseHold: Locking $fname\n";
	}

	sub pauseSetSessionCount($) {
		my ($sessCount) = @_;
		my $fh;
		openLockFH(\$fh,$fSessionCount) or die "pauseSetSessionCount: could not open $fSessionCount\n";
		print $fh $sessCount;
		close($fh);
	}


	sub pauseDecrementSessionCount {
		my $fh;

		openLockFH(\$fh,$fSessionCount) or die "pauseSetSessionCount: could not open $fSessionCount\n";

		if ( ! defined($fh) ) {
			die "pauseDecrementSessionCount: failed to open $fSessionCount \n";
		}

		seek($fh,0,0);
		my $sessCount=<$fh>;
		#print "pauseDecrementSessionCount - value read: $sessCount\n";
		$sessCount--;
		seek($fh,0,0);
		# printing as a formatted string
		# this ensures that all digits in the file get overwritten
		# for instance: 10 sessions are started and 10 is written to this file
		# first session to decrement the value gets a result of 9
		# '9' is written to the file.
		# But, there is a 0 in the second positin, left over from 10
		# so now the next session will see 90.
		# padded to 6 digits presents that.
		my $sessCountString = sprintf("%6d",$sessCount);
		#print "pauseDecrementSessionCount - value written $sessCountString\n";
		print $fh $sessCountString;
		$fh->close();

	}

	sub pauseCheckSessionCount {
		my $fh;
		openLockFH(\$fh,$fSessionCount) or die "pauseCheckSessionCount: could not open $fSessionCount\n";;
		seek($fh,0,0);
		my $sessCount=<$fh>;
		#print "pauseCheckSessionCount: $sessCount\n";
		close($fh);

		# value is written as padded string with lenght of 6
		# see notes in sub pauseDecrementSessionCount
		# add 0 to ensure a number is returned
		return $sessCount+0;
	}

	sub pauseRelease {
		my $fh;
		openLockFH(\$fh,$fname) or die "pauseRelease: could not open $fname\n";;

		seek($fh,0,0);
		print $fh '1';
		close($fh);
	
	}

	sub pauseCheckHold {
		my $fh; 

		openLockFH(\$fh,$fname) or die "pauseCheckHold: could not open $fname\n";;

		seek($fh,0,0);
		my $lockByte = <$fh>;
		close($fh);
		#print "pauseCheckHold: LockByte: $lockByte\n";
		return $lockByte;
	}

	sub pauseLockCleanup { 
		#print "pauseLockCleanup - fname: $fname\n";
		#print "pauseLockCleanup - fSessionCount: $fSessionCount\n";
		unlink $fname if -r $fname;
		unlink $fSessionCount if -r $fSessionCount;
	}

}
# end of pause subs

# get db name - brand, not individual name
# returns lowercase name - oracle,mysql, ??
# see DBI get_info docs
sub getDbName($) {
	my ($dbh) = @_;
	return lc($dbh->get_info( 17 ));
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
	'postgresql' => \&_setPgParms, # if there is an equivalent
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

# this is where you might set postgresql parameters
# see _setOracleParms

sub _setPgParms {
	my ($dbh,$debug,$parms) = @_;

	# do nothing for now
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
	'postgresql' =>  \&_setPgSchema,
);

# this is where you might set schema options
# see _setOracleSchema
sub _setPgSchema {
	my ($dbh,$debug,$schema) = @_;
	return 1; # needs code
}

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

my %traceUnsetters = (
	'oracle' => \&_unsetOracleTrace,
	'mysql' => \&_unsetMySQLTrace, # if there is an equivalent
);


# oracle only
my %clientResultCacheTraceSetters = (
	'oracle' => \&_setOracleClientResultTrace,
	'mysql' => sub{return;} , # if there is an equivalent
);

my %clientResultCacheTraceUnsetters = (
	'oracle' => \&_unsetOracleClientResultTrace,
	'mysql' => sub{return;} , # if there is an equivalent
);


sub _setOracleTrace {
	my ($dbh,$debug,$traceFileID) = @_;

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

sub _unsetOracleTrace {
	my ($dbh,$debug,$traceFileID) = @_;

	eval { 
		local $dbh->{RaiseError} = 0;
		local $dbh->{PrintError} = 1;
		$dbh->do(qq{alter session set events '10046 trace name context off'});
	};

	if ($@) {
					my($err,$errStr) = ($dbh->err, $dbh->errstr);
			die "Error $err, $errStr encountered disabling 10046 trace\n";
	}
}

sub _setOracleClientResultTrace {
	my ($dbh,$debug) = @_;
	eval { 
		local $dbh->{RaiseError} = 0;
		local $dbh->{PrintError} = 1;
		$dbh->do(qq{alter session set events '10843 trace name context forever, level 12'});
	};

	if ($@) {
		my($err,$errStr) = ($dbh->err, $dbh->errstr);
		die "Error $err, $errStr encountered setting 10843 trace on\n";
	}
}

sub _unsetOracleClientResultTrace {
	my ($dbh,$debug) = @_;
	eval { 
		local $dbh->{RaiseError} = 0;
		local $dbh->{PrintError} = 1;
		$dbh->do(qq{alter session set events '10043 trace name context off'});
	};

	if ($@) {
					my($err,$errStr) = ($dbh->err, $dbh->errstr);
			die "Error $err, $errStr encountered disabling 10043 trace\n";
	}
}

# just a stub - needs code 
sub _setMySQLTrace {
	my ($dbh,$debug,$trace) = @_;
	return 1;
}

sub _unsetMySQLTrace {
	my ($dbh,$debug,$trace) = @_;
	return 1;
}

# just a stub - needs code 
sub _setPgTrace {
	my ($dbh,$debug,$trace) = @_;
	return 1;
}

sub setDbTrace($$$$) {
	my ($dbh,$debug,$traceFileID,$traceLevel) = @_;
	$traceSetters{getDbName($dbh)}->($dbh,$debug,$traceFileID);
};

sub unsetDbTrace($$$) {
	my ($dbh,$debug,$traceFileID) = @_;
	$traceSetters{getDbName($dbh)}->($dbh,$debug,$traceFileID);
};

sub setClientResultCacheTrace {
	my ($dbh,$debug) = @_;
	$clientResultCacheTraceSetters{getDbName($dbh)}->($dbh,$debug);
}

sub unsetClientResultCacheTrace {
	my ($dbh,$debug) = @_;
	$clientResultCacheTraceUnsetters{getDbName($dbh)}->($dbh,$debug);
}

sub new {
	my $pkg = shift;
	my $class = ref($pkg) || $pkg;
	#print "Class: $class\n";
	my (%args) = @_;

	#my $traceFileID='';

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

		#my $timestamp = qq(${year}${mon}${wday}${hour}${min}${sec});
		#$traceFileID = qq(SQLRUN-${timestamp});
		#$args{TRACEFILEID} .= '-' . $timestamp;
		#print "tracefile_identifier = $traceFileID\n";
		print "tracefile_identifier = $args{TRACEFILEID}\n";

	}

	#$args{TRACEFILEID} = $traceFileID;

	my $retval = bless \%args, $class;
	#print 'Sqlrun::new retval: ' . Dumper($retval);
	return $retval;
}

sub child {
	my $self = shift;

	my $debug = $self->{DEBUG};

	#if ($debug) { print "Child IS in debug mode\n" }
	#else { print "Child is NOT in debug mode\n" }

	my $pid = fork;
	print "PID: $pid\n" if $self->{VERBOSE};

	unless ($pid) {
		$pid = fork;
		unless ($pid) {
			print qq{

DOIT: 
db: $self->{DB}
username: $self->{USERNAME}
			\n} if $debug;

			#print "child DRIVER:  $self->{DRIVER}\n";
			#print "child DRIVERCONFIGFILE:  $self->{DRIVERCONFIGFILE}\n";

			my $dbh;
			my $connection = new Sqlrun::Connect (
				DRIVER => $self->{DRIVER},
				SETUP => $self->{SETUP},
				DRIVERCONFIGFILE => $self->{DRIVERCONFIGFILE},
			);

			#print "Sqlrun::child calling new connection\n";
			$dbh = $connection->connect or die "dbh failed in Sqlrun child - $!\n";

			die "Connect to $self->{DATABASE} failed \n" unless $dbh;

			$dbh->{RowCacheSize} = $self->{ROWCACHESIZE};

			# seed rand for child
			srand($$);

			setParms($dbh,$self->{DEBUG},$self->{PARAMETERS});

			setSchema($dbh,$self->{DEBUG},$self->{SCHEMA});

			# sets 10046 trace in Oracle
			# code needed for other databases
			if ($self->{TRACE}) {
				setDbTrace($dbh,$self->{DEBUG},$self->{TRACEFILEID},$self->{TRACELEVEL});
			}

			if ($self->{CLIENTRESULTCACHETRACE}) {
				setClientResultCacheTrace($dbh,$self->{DEBUG});
			}


			#print "Child Self " , Dumper($self);

			# tsunami mode waits until all connections made before executing test SQL
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
			# number of of time through loop 
			my $exeLoops=0; 

			foreach my $bindKey ( keys %{$binds} ) {
				my @bindSet = @{$binds->{$bindKey}};
				$bindSetMax{$bindKey} = $#bindSet;
				$bindSetNum{$bindKey} = 0;
			}

			print "Timer Check: ", $$timer->check(), "\n" if $self->{VERBOSE};

			while ($$timer->check() > 0 ) {

				print "Past Timer Check\n" if $debug;

# need to modify starting here
# sql and type now stored in an array
# see code at end of test script classify-sql.pl 

				print "Last El: $#{$sql}\n" if $debug;
				$currSqlNum = getNextSql($currSqlNum,$#{$sql},$self->{EXEMODE});
				print "SQL Number: $currSqlNum\n" if $debug;

				my %tmpHash = %{$sql->[$currSqlNum]};
				#print 'Tmp HASH: ', Dumper(\%tmpHash) if $debug;

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

				$exeLoops++;
				usleep($self->{EXEDELAY} * 10**6);
			}

my $flockSleepTime = 10_000; # microseconds
my $flockSleepIterMax = 1000; # 10 seconds total attempting to lock file

			if ( $self->{TXTALLYCOUNT} ) {
				my $rcfh;

				for (my $i=0; $i < $flockSleepIterMax; $i++) {

					eval {

						use warnings FATAL => 'all';
						# possibility of race - use flock

						if ( open( $rcfh, '>>', $self->{TXTALLTCOUNTFILE}) ) {
							flock($rcfh, LOCK_EX) or die "Cannot lock $self->{TXTALLTCOUNTFILE} - $!\n";
							print $rcfh "$self->{TRACEFILEID}: $exeLoops\n";
						} else {
							close($rcfh);
							die;
						}
					

					};

					if ($@) {
						usleep($flockSleepTime);
					} else {
						last;
					}

				};

				if ( ! defined($rcfh) ) {
					 warn "Could not open $self->{TXTALLTCOUNTFILE}\n"
				}
				close($rcfh);
			}

			if ( $self->{PAUSEATEXIT} ) {

				print "Child $$ is waiting\n";
				$self->pauseDecrementSessionCount();

				while (! $self->pauseCheckHold()) {
					#print "Child $$ is waiting\n";
					usleep(250000);
				}
			}

			if ($self->{TRACE}) {
				unsetDbTrace($dbh,$self->{DEBUG},$self->{TRACEFILEID});
			}

			if ($self->{CLIENTRESULTCACHETRACE}) {
				unsetClientResultCacheTraceOff($dbh,$self->{DEBUG});
			}

			$dbh->disconnect;

			#print Dumper($self);
			exit 0;
		}
		exit 0;
	}
	print "Waiting on child $pid...\n" if $self->{VERBOSE};
	waitpid($pid,0);

}


1;


