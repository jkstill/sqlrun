
######################################################

=head1 Sqlrun


=cut


package Sqlrun;

require Exporter;
our @ISA= qw(Exporter);
#our @EXPORT_OK = ( 'sub-1','sub-2');
our $VERSION = '0.01';

sub new {
	my $pkg = shift;
	my $class = ref($pkg) || $pkg;
	#print "Class: $class\n";
	my ($args) = @_;
	#      #print 'args: ' , Dumper($args);
	#

	my $self = {
		EXEDELAY => $args->{EXEDELAY},
		EXEMODE => $args->{EXEMOTE},
		STARTTIME => $args->{STARTTIME},
		PARAMETERS => \%parameters,
		BINDS => \%binds,
		SQLPARMS => \%sqlParms,
		SQL => \@sql
	};

	my $retval = bless $self, $class;
	return $retval;
}


######################################################

=head1 Sqlrun::Timer


=cut

package Sqlrun::Timer;

require Exporter;
our @ISA= qw(Exporter);
#our @EXPORT_OK = ( 'sub-1','sub-2');
our $VERSION = '0.01';

sub new {

	my $pkg = shift;
	my $class = ref($pkg) || $pkg;
	#print "Class: $class\n";
	my ($args) = @_;
	#      #print 'args: ' , Dumper($args);
	#

	my $self = {
		START => time,
		DURATION => $args->{DURATION}.
		REMAINING => $args->{DURATION}	 	
	};

	my $retval = bless $self, $class;
	return $retval;

}


# returns time remaining (seconds)
# 0 or negative return value indicates time is up
sub check {
	my $self = shift;
	my $elapsed = time - $self->{START};
	my $remaining =  ($self->{START}  + $self->{DURATION}) - time;

	$self->{REMAINING}  = $remaining;
	return $remaining;
}


1;


