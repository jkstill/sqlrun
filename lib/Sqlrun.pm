
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


sub new {
	my $pkg = shift;
	my $class = ref($pkg) || $pkg;
	#print "Class: $class\n";
	my (%args) = @_;

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
				print "Parameter: $parameterName\n";
				print "Value: ${$self->{PARAMETERS}}{$parameterName}\n";

				eval { 
					local $dbh->{RaiseError} = 0;
					local $dbh->{PrintError} = 1;
					$dbh->do(qq{alter session set $parameterName = '${$self->{PARAMETERS}}{$parameterName}'});
				};

				if ($@) {
					   my($err,$errStr) = ($dbh->err, $dbh->errstr);
						warn "Erorr $err, $errStr encountered setting $parameterName\n";
				}
			}

			if ($self->{CONNECTMODE} eq 'tsunami') {
				print "Child $$ is waiting\n";
				while (! $self->checkHold()) {
					#print "Child $$ is waiting\n";
					usleep(250000);
				}
			}

			my $timer = $self->{TIMER};

			while ($$timer->check() > 0 ) {
				my $sql=q{select 'OOP Connection Test' test, user, sys_context('userenv','sid') SID, sysdate, systimestamp from dual};
				my $sth = $dbh->prepare($sql,{ora_check_sql => 0});

				$sth->execute;

				while( my $ary = $sth->fetchrow_arrayref ) {
					warn join(' - ',@{$ary}),"\n";
				}

				usleep($self->{EXEDELAY} * 10**6);
			}

			$dbh->disconnect;

			#print Dumper($self);
			exit 0;
		}
		exit 0;
	}
	waitpid($pid,0);

}


1;


