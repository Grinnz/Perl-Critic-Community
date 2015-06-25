package Perl::Critic::Policy::Freenode::AssignToDollarUnderscore;

use strict;
use warnings;

use Perl::Critic::Utils qw(:severities :classification :ppi);
use parent 'Perl::Critic::Policy';

our $VERSION = '0.001';

use constant DESC => 'Explicit assignment to $_';
use constant EXPL => 'Assigning to $_ without localizing it will clobber the value being used by any outer loop. Use a lexical (my) variable instead.';

sub supported_parameters { () }
sub default_severity { $SEVERITY_MEDIUM }
sub default_themes { 'freenode' }
sub applies_to { 'PPI::Token::Operator' }

sub violates {
	my ($self, $elem) = @_;
	# Check for assignment operator
	return () unless $elem =~ /(?<![!=<>])=\z/;
	
	my $previous = $elem->sprevious_sibling || return ();
	return $self->violation(DESC, EXPL, $elem) if $previous->isa('PPI::Token::Symbol')
		and $previous eq '$_';
	
	return ();
}

1;

=head1 NAME

Perl::Critic::Policy::Freenode::AssignToDollarUnderscore

=head1 DESCRIPTION

The special variable C<$_> is a global variable, and explicitly assigning to it
without localizing it will overwrite the contents, even in the middle of a loop
that is already using it. Most implicit assignments to C<$_> (such as with
C<for> or C<grep>) will also implicitly localize the variable. For explicit
assignment, use a lexical variable instead.

  $_ = 'foo';        # not ok
  my $topic = 'foo'; # ok

=head1 AFFILIATION

This policy is part of L<Perl::Critic::Freenode>.

=head1 CONFIGURATION

This policy is not configurable except for the standard options.

=head1 AUTHOR

Dan Book, C<dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2015, Dan Book.

This library is free software; you may redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Perl::Critic>
