package Perl::Critic::Policy::Freenode::DeprecatedFeatures;

use strict;
use warnings;

use Perl::Critic::Utils qw(:severities :classification :ppi);
use Perl::Critic::Violation;
use parent 'Perl::Critic::Policy';

our $VERSION = '0.011';

sub supported_parameters { () }
sub default_severity { $SEVERITY_HIGH }
sub default_themes { 'freenode' }
sub applies_to { 'PPI::Element' }

my %features = (
	'$[' => {
		expl => 'Use of $[ is deprecated in perl v5.12.0. See Array::Base and String::Base.',
	},
	':=' => {
		expl => 'Use of := as an empty attribute list is deprecated in perl v5.12.0, use = alone.',
	},
	'UNIVERSAL->import()' => {
		expl => 'The method UNIVERSAL->import() (or passing import arguments to "use UNIVERSAL") is deprecated in perl v5.12.0.',
	},
);

sub _violation {
	my ($self, $feature, $elem) = @_;
	my $desc = "Used deprecated feature $feature";
	my $expl = $features{$feature}{expl} // "Feature $feature is deprecated.";
	my $severity = $features{$feature}{severity} // $self->default_severity;
	return Perl::Critic::Violation->new($desc, $expl, $elem, $severity);
}

sub violates {
	my ($self, $elem) = @_;
	my $next;
	my @args;
	if ($elem->isa('PPI::Statement')) {
		if ($elem->isa('PPI::Statement::Include') and $elem->type eq 'use'
		         and $elem->module eq 'UNIVERSAL' and @args = $elem->arguments
		         and (!$args[0]->isa('PPI::Structure::List') or $args[0]->schildren)) {
			return $self->_violation('UNIVERSAL->import()', $elem);
		}
	} elsif ($elem->isa('PPI::Token')) {
		if ($elem->isa('PPI::Token::Symbol')) {
			if ($elem eq '$[') {
				return $self->_violation('$[', $elem);
			}
		} elsif ($elem->isa('PPI::Token::Operator')) {
			if ($elem eq ':' and $next = $elem->next_sibling and $next->isa('PPI::Token::Operator') and $next eq '=') {
				return $self->_violation(':=', $elem);
			}
		} elsif ($elem->isa('PPI::Token::Word')) {
			if ($elem eq 'UNIVERSAL'
		        and $next = $elem->snext_sibling and $next->isa('PPI::Token::Operator') and $next eq '->'
		        and $next = $next->snext_sibling and $next->isa('PPI::Token::Word') and $next eq 'import') {
				return $self->_violation('UNIVERSAL->import()', $next);
			}
		}
	}
	return ();
}

1;

=head1 NAME

Perl::Critic::Policy::Freenode::DeprecatedFeatures - Avoid features that have
been deprecated or removed from Perl

=head1 DESCRIPTION

While L<Perl::Critic::Policy::Freenode::StrictWarnings> will expose usage of
deprecated or removed features when a modern perl is used, this policy will
detect such features in use regardless of perl version, as these features are
usually deprecated for a good reason.

=head1 FEATURES

=head2 $[

The magic L<perlvar/"$["> variable was used in very old perls to determine the
index of the first element of arrays or the first character in substrings, and
also allow modifying this value. It was discouraged from the start of Perl 5,
its functionality changed in v5.10.0, deprecated in v5.12.0, re-implemented as
L<arybase>.pm in v5.16.0, and it is essentially a synonym for C<0> under
C<use v5.16> or C<no feature "array_base">. While it is probably a bad idea in
general, the modules L<Array::Base> and L<String::Base> can now be used to
replace this functionality.

=head2 :=

Because the whitespace between an attribute list and assignment operator is not
significant, it was possible to specify assignment to a variable with an empty
attribute list with a construction like C<my $foo := 'bar'>. This was
deprecated in perl v5.12.0 to allow the possibility of a future C<:=> operator.
Avoid the issue by either putting whitespace between the C<:> and C<=>
characters or simply omitting the empty attribute list.

=head2 UNIVERSAL->import()

The method C<UNIVERSAL->import()> and similarly passing import arguments to
C<use UNIVERSAL> was deprecated in perl v5.12.0.

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
