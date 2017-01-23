
######################################################

=head1 Sqlrun


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
our $VERSION = '0.01';

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

#sub getNextSql($currSqlNum,$sql,$self->{EXEMODE});
sub getNextSql {
	my ($currSqlNum,$maxElement,$exeMode) = @_;

	if ($exeMode eq 'sequential') {
		return 0 unless $currSqlNum;
		if ($currSqlNum == $maxElement) {
			return 0;
		} else { return $currSqlNum++ }
	} elsif (
		$exeMode eq 'semi-random' 
		or $exeMode eq 'truly-random'
	) {
		return int(rand($maxElement));
	} else { die "unknown exeMode of $exeMode in Sqlrun::getNextSql\n" }

}

sub getNextBindNum {
	my ($setNum, $setMax) = @_;
	if ($setNum < $setMax) { return $setNum++ }
	else { return 0}
}


sub new {
	my $pkg = shift;
	my $class = ref($pkg) || $pkg;
	#print "Class: $class\n";
	my (%args) = @_;

	my $traceFileID='';

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

	my $pid = fork;
	print "PID: $pid\n";
	#die "forking error 1 in Sqlrun.pm\n" unless $pid;
	#
	# child PID returned to parent
	# 0 returned to child

	unless ($pid) {
		$pid = fork;
		unless ($pid) {
			print qq{

DOIT: 
db: $self->{DB}
username: $self->{USERNAME}
			\n} if $debug;

			my $dbh = DBI->connect(
				'dbi:Oracle:' . $self->{DB},
				$self->{USERNAME},$self->{PASSWORD},
				{
					RaiseError => 1,
					AutoCommit => 0,
					ora_session_mode => $self->{DBCONNECTIONMODE},
				}
			);

			die "Connect to $self->{DATABASE} failed \n" unless $dbh;

			$dbh->{RowCacheSize} = $self->{ROWCACHESIZE};

			# process any session parameters
			foreach my $parameterName ( keys %{$self->{PARAMETERS}}) {
				print "Parameter: $parameterName\n" if $debug;
				print "Value: ${$self->{PARAMETERS}}{$parameterName}\n" if $debug;

				eval { 
					local $dbh->{RaiseError} = 0;
					local $dbh->{PrintError} = 1;
					$dbh->do(qq{alter session set $parameterName = '${$self->{PARAMETERS}}{$parameterName}'});
				};

				if ($@) {
					   my($err,$errStr) = ($dbh->err, $dbh->errstr);
						warn "Error $err, $errStr encountered setting $parameterName\n";
				}
			}

			if ($self->{SCHEMA}) {
				eval { 
					local $dbh->{RaiseError} = 0;
					local $dbh->{PrintError} = 1;
					$dbh->do(qq{alter session set current_schema = $self->{SCHEMA}});
				};

				if ($@) {
					   my($err,$errStr) = ($dbh->err, $dbh->errstr);
						die "Error $err, $errStr encountered setting current_schema = $self->{SCHEMA} \n";
				}
			}

			#print "Child Self " , Dumper($self);

			if ($self->{TRACE}) {
				my $traceFileID = $self->{TRACEFILEID};

				#print "CHILD TRACEFILE ID: $traceFileID\n" if $debug;

				eval { 
					local $dbh->{RaiseError} = 0;
					local $dbh->{PrintError} = 1;
					$dbh->do(qq{alter session set tracefile_identifier='${traceFileID}'});
				};

				if ($@) {
					   my($err,$errStr) = ($dbh->err, $dbh->errstr);
						die "Error $err, $errStr encountered setting tracefile_identifier = ${traceFileID} \n";
				}

				my $sql = qq{select i.host_name || '.' || d.value
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
						die "Error $err, $errStr encountered setting current_schema = $self->{SCHEMA} \n";
				}
			}


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

			foreach my $bindKey ( keys %{$binds} ) {
				my @bindSet = @{$binds->{$bindKey}};
				$bindSetMax{$bindKey} = $#bindSet;
				$bindSetNum{$bindKey} = 0;
			}

			while ($$timer->check() > 0 ) {

				$currSqlNum = getNextSql($currSqlNum,$#{$sql},$self->{EXEMODE});
				print "SQL Number: $currSqlNum\n" if $debug;

				my %tmpHash = %{$sql->[$currSqlNum]};
				print 'Tmp HASH: ', Dumper(\%tmpHash) if $debug;

				# only 1 element in this hash
				my @sqlNames = map { $_ } keys %tmpHash;
				my $sqlName = pop @sqlNames;

				print "SQL Name: $sqlName\n" if $debug;

				unless ($handles{$sqlName})  { 
					$handles{$sqlName} = $dbh->prepare($tmpHash{$sqlName},{ora_check_sql => 0});
				}

				if ($binds->{$sqlName}) {
					my $bindNum = getNextBindNum($bindSetNum{$sqlName}, $bindSetMax{$sqlName});
					my $bindSet = $binds->{$sqlName};
					#print 'BIND SET: ' , Dumper($bindSet) if $debug;
					$handles{$sqlName}->execute($bindSet->[$bindNum]);
				} else {
					$handles{$sqlName}->execute;
				}

				while( my $ary = $handles{$sqlName}->fetchrow_arrayref ) {
					#warn "RESULTS\n";
					#warn join(' - ',@{$ary}),"\n";

					# probably should put some logging here
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


