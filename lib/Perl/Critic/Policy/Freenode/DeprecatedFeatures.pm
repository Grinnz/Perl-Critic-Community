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
sub applies_to { 'PPI::Token' }

my %features = (
	'$[' => {
		expl => 'Use of $[ is deprecated in perl v5.12.0. See Array::Base and String::Base.',
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
	if ($elem->isa('PPI::Token::Symbol') and $elem eq '$[') {
		return $self->_violation('$[', $elem);
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
