package Perl::Critic::Policy::Freenode::EmptyReturn;

use strict;
use warnings;

use Perl::Critic::Utils qw(:severities :classification :ppi);
use parent 'Perl::Critic::Policy';

use List::Util 'any';

our $VERSION = '0.006';

use constant DESC => 'return() called with no arguments';
use constant EXPL => 'return() with no arguments may return either undef or an empty list depending on context. This can be surprising for the same reason as other context-sensitive returns. Return undef or the empty list explicitly.';

sub supported_parameters { () }
sub default_severity { $SEVERITY_LOWEST }
sub default_themes { 'freenode' }
sub applies_to { 'PPI::Statement::Break' }

sub violates {
	my ($self, $elem) = @_;
	my @children = $elem->schildren;
	my $function = shift @children // return ();
	return () unless $function eq 'return' and is_function_call $function;
	
	return $self->violation(DESC, EXPL, $elem) unless any { $_ ne ';' } @children;
	
	return ();
}

1;

=head1 NAME

Perl::Critic::Policy::Freenode::EmptyReturn - Don't use return with no
arguments

=head1 DESCRIPTION

Context-sensitive functions, while one way to write functions that DWIM (Do
What I Mean), tend to instead lead to unexpected behavior when the function is
accidentally used in a different context, especially if the function's behavior
changes significantly based on context. This also can lead to vulnerabilities
when a function is intended to be used as a scalar, but is used in a list, such
as a hash constructor or function parameter list. C<return> with no arguments
will return either C<undef> or an empty list depending on context. Instead,
return the appropriate value explicitly.

  return;       # not ok
  return ();    # ok
  return undef; # ok

=head1 AFFILIATION

This policy is part of L<Perl::Critic::Freenode>.

=head1 CONFIGURATION

This policy is not configurable except for the standard options.

=head1 CAVEATS

This policy currently does not detect an empty return which has a conditional
modifier, such as C<return if $foo;>.

=head1 AUTHOR

Dan Book, C<dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2015, Dan Book.

This library is free software; you may redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Perl::Critic>
