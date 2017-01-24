

# Jared Still
# 2017-01-24
# jkstill@gmail.com
# still@pythian.com

######################################################

=head1 Sqlrun::Timer

Not yet documented

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


