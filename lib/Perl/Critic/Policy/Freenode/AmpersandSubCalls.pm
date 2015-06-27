package Perl::Critic::Policy::Freenode::AmpersandSubCalls;

use strict;
use warnings;

use Perl::Critic::Utils qw(:severities :classification :ppi);
use parent 'Perl::Critic::Policy';

our $VERSION = '0.004';

use constant DESC => 'Subroutine called with ampersand (&)';
use constant EXPL => 'The ampersand is not required to call subroutines, and actually introduces extra functionality you may not expect. Call subroutines as barewords: foo() not &foo()';

sub supported_parameters { () }
sub default_severity { $SEVERITY_HIGH }
sub default_themes { 'freenode' }
sub applies_to { 'PPI::Token::Symbol' }

sub violates {
	my ($self, $elem) = @_;
	return () unless $elem->raw_type eq '&';
	
	my $prev = $elem->sprevious_sibling;
	return () if $prev and $prev->isa('PPI::Token::Cast') and $prev eq '\\';
	return () if $prev and $prev->isa('PPI::Token::Word') and $prev eq 'goto';
	
	return $self->violation(DESC, EXPL, $elem);
}

1;

=head1 NAME

Perl::Critic::Policy::Freenode::AmpersandSubCalls - Don't use & to call
subroutines

=head1 DESCRIPTION

Ampersands (C<&>) were once needed to call subroutines, but in modern Perl they
are not only unnecessary but actually change the behavior from what you may
expect. Calling a subroutine with an ampersand ignores the subroutine's
prototype if any, which may change what arguments the subroutine receives.
Additionally, calling a subroutine as C<&foo;> with no arguments will pass on
the contents of C<@_> from the current subroutine, which may be quite
surprising. Unless used intentionally for this behavior, the ampersand should
simply be omitted.

  my $value = &foo();  # not ok
  my $sum = &foo(1,2); # not ok
  my $value = foo();   # ok
  my $sum = foo 1,2;   # ok

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
