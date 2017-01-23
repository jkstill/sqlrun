
######################################################

=head1 Sqlrun


=cut


package Sqlrun;

use warnings;
use strict;
use DBI;
use Data::Dumper;

require Exporter;
our @ISA= qw(Exporter);
our @EXPORT_OK = q();
our $VERSION = '0.01';

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
password: $self->{PASSWORD}
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

			my $sql=q{select 'OOP Connection Test' test, user, sys_context('userenv','sid') SID from dual};

			my $sth = $dbh->prepare($sql,{ora_check_sql => 0});

			$sth->execute;

			while( my $ary = $sth->fetchrow_arrayref ) {
				warn join(' - ',@{$ary}),"\n";
			}

				$dbh->disconnect;
				exit 0;
			}
			exit 0;
		}
	waitpid($pid,0);

}


1;


