package Perl::Critic::Policy::Freenode::StrictWarnings;

use strict;
use warnings;

use Perl::Critic::Utils qw(:severities :classification :ppi);
use parent 'Perl::Critic::Policy';

use List::Util 'any';

our $VERSION = '0.001';

use constant DESC => 'Missing strict or warnings';
use constant EXPL => 'Strict and warnings are important to avoid common pitfalls and deprecated/experimental functionality.';

sub supported_parameters { () }
sub default_severity { $SEVERITY_HIGH }
sub default_themes { 'freenode' }
sub applies_to { 'PPI::Document' }

sub violates {
	my ($self, $elem) = @_;
	my $includes = $elem->find('PPI::Statement::Include') || [];
	unless (any { $_->pragma eq 'strict' } @$includes
	    and any { $_->pragma eq 'warnings' } @$includes) {
		return $self->violation(DESC, EXPL, $elem);
	}
	return ();
}

1;
