package Perl::Critic::Policy::Freenode::DeprecatedFeatures;

use strict;
use warnings;

use List::Util 'any', 'none';
use Perl::Critic::Utils qw(:severities :classification :ppi);
use Perl::Critic::Violation;
use parent 'Perl::Critic::Policy';

our $VERSION = '0.011';

sub supported_parameters { () }
sub default_severity { $SEVERITY_HIGH }
sub default_themes { 'freenode' }
sub applies_to { 'PPI::Element' }

my %features = (
	':=' => {
		expl => 'Use of := as an empty attribute list is deprecated in perl v5.12.0, use = alone.',
	},
	'$[' => {
		expl => 'Use of $[ is deprecated in perl v5.12.0. See Array::Base and String::Base.',
	},
	'?PATTERN?' => {
		expl => 'Use of ? as a match regex delimiter without an initial m is deprecated in perl v5.14.0. Use m?PATTERN? instead.',
	},
	'defined on array/hash' => {
		expl => 'Use of defined() on an array or hash is deprecated in perl v5.6.2. The array or hash can be tested directly to check for non-emptiness: if (@foo) { ... }',
	},
	'do SUBROUTINE(LIST)' => {
		expl => 'Use of do to call a subroutine is deprecated in perl 5.',
	},
	'POSIX character function' => {
		expl => 'Several character matching functions in POSIX.pm are deprecated in perl v5.20.0: isalnum, isalpha, iscntrl, isdigit, isgraph, islower, isprint, ispunct, isspace, isupper, and isxdigit. Regular expressions are a more portable and correct way to test character strings.',
	},
	'qw(...) as parentheses' => {
		expl => 'Use of qw(...) as parentheses is deprecated in perl v5.14.0. Wrap the list in literal parentheses when required, such as in a foreach loop.',
	},
	'UNIVERSAL->import()' => {
		expl => 'The method UNIVERSAL->import() (or passing import arguments to "use UNIVERSAL") is deprecated in perl v5.12.0.',
	},
);

my %posix_deprecated = map { ($_ => 1) }
	qw(isalnum isalpha iscntrl isdigit isgraph islower isprint ispunct isspace isupper isxdigit);

sub _violation {
	my ($self, $feature, $elem) = @_;
	my $desc = "$feature is deprecated";
	my $expl = $features{$feature}{expl} // "$feature is deprecated or removed from recent versions of Perl.";
	my $severity = $features{$feature}{severity} // $self->default_severity;
	return Perl::Critic::Violation->new($desc, $expl, $elem, $severity);
}

sub violates {
	my ($self, $elem) = @_;
	my $next;
	my $parent;
	my @args;
	if ($elem->isa('PPI::Statement')) {
		# use UNIVERSAL ...;
		if ($elem->isa('PPI::Statement::Include')) {
			if ($elem->type eq 'use' and $elem->module eq 'UNIVERSAL' and @args = $elem->arguments
		        and (!$args[0]->isa('PPI::Structure::List') or $args[0]->schildren)) {
				return $self->_violation('UNIVERSAL->import()', $elem);
			}
		}
	} elsif ($elem->isa('PPI::Token')) {
		if ($elem->isa('PPI::Token::Symbol')) {
			# $[
			if ($elem eq '$[') {
				return $self->_violation('$[', $elem);
			}
		} elsif ($elem->isa('PPI::Token::Operator')) {
			# :=
			if ($elem eq ':' and $next = $elem->next_sibling and $next->isa('PPI::Token::Operator') and $next eq '=') {
				return $self->_violation(':=', $elem);
			# ?PATTERN?
			} elsif ($elem eq '?' and $parent = $elem->parent and $parent->isa('PPI::Statement')) {
				$next = $elem->snext_sibling;
				until (!$next or ($next->isa('PPI::Token::Operator') and $next eq '?')) {
					$next = $next->snext_sibling;
				}
				# If the statement has a : operator, this is probably a ternary operator.
				# PPI also tends to detect the : as a loop label.
				if ($next and none { ($_->isa('PPI::Token::Operator') and $_ eq ':') or $_->isa('PPI::Token::Label') } $parent->schildren) {
					return $self->_violation('?PATTERN?', $elem);
				}
			}
		} elsif ($elem->isa('PPI::Token::Word')) {
			# UNIVERSAL->import()
			if ($elem eq 'UNIVERSAL'
		        and $next = $elem->snext_sibling and $next->isa('PPI::Token::Operator') and $next eq '->'
		        and $next = $next->snext_sibling and $next->isa('PPI::Token::Word') and $next eq 'import') {
				return $self->_violation('UNIVERSAL->import()', $next);
			# for $x qw(...)
			} elsif (($elem eq 'for' or $elem eq 'foreach') and !$elem->sprevious_sibling) {
				$next = $elem->snext_sibling;
				until (!$next or $next->isa('PPI::Structure::List')
				       or $next->isa('PPI::Token::QuoteLike::Words')) {
					$next = $next->snext_sibling;
				}
				if ($next and $next->isa('PPI::Token::QuoteLike::Words')) {
					return $self->_violation('qw(...) as parentheses', $next);
				}
			# do SUBROUTINE(LIST)
			} elsif ($elem eq 'do' and $next = $elem->snext_sibling) {
				if ((($next->isa('PPI::Token::Word') and is_function_call $next)
				    or ($next->isa('PPI::Token::Symbol') and ($next->raw_type eq '&' or $next->raw_type eq '$')))
				    and ($next = $next->snext_sibling and $next->isa('PPI::Structure::List'))) {
					return $self->_violation('do SUBROUTINE(LIST)', $elem);
				}
			# POSIX character function
			} elsif (exists $posix_deprecated{$elem}) {
				my $includes = $elem->document->find('PPI::Statement::Include') || [];
				if (any { ($_->module // '') eq 'POSIX' } @$includes) {
					return $self->_violation('POSIX character function', $elem);
				}
			# defined array/hash
			} elsif ($elem eq 'defined' and $next = $elem->snext_sibling) {
				$next = $next->schild(0) if $next->isa('PPI::Structure::List');
				if ($next and $next->isa('PPI::Token::Symbol')
				    and ($next->raw_type eq '@' or $next->raw_type eq '%')
				    and $next->raw_type eq $next->symbol_type) {
					return $self->_violation('defined on array/hash', $elem);
				}
			}
		} elsif ($elem->isa('PPI::Token::Regexp')) {
			# ?PATTERN?
			if ($elem->isa('PPI::Token::Regexp::Match') and ($elem->get_delimiters)[0] eq '?' and $elem !~ m/^m/) {
				return $self->_violation('?PATTERN?', $elem);
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
detect such features in use regardless of perl version, to assist in keeping
your code modern and forward-compatible.

=head1 FEATURES

=head2 :=

Because the whitespace between an attribute list and assignment operator is not
significant, it was possible to specify assignment to a variable with an empty
attribute list with a construction like C<my $foo := 'bar'>. This is deprecated
in perl v5.12.0 to allow the possibility of a future C<:=> operator. Avoid the
issue by either putting whitespace between the C<:> and C<=> characters or
simply omitting the empty attribute list.

=head2 $[

The magic L<perlvar/"$["> variable was used in very old perls to determine the
index of the first element of arrays or the first character in substrings, and
also allow modifying this value. It was discouraged from the start of Perl 5,
its functionality changed in v5.10.0, deprecated in v5.12.0, re-implemented as
L<arybase>.pm in v5.16.0, and it is essentially a synonym for C<0> under
C<use v5.16> or C<no feature "array_base">. While it is probably a bad idea in
general, the modules L<Array::Base> and L<String::Base> can now be used to
replace this functionality.

=head2 ?PATTERN?

The C<?PATTERN?> regex match syntax is deprecated in perl v5.14.0 and removed
in perl v5.22.0. Use C<m?PATTERN?> instead.

=head2 defined on array/hash

Using the function C<defined()> on an array or hash probably does not do what
you expected, and is deprecated in perl v5.6.2 and throws a fatal error in perl
v5.22.0. To check if an array or hash is non-empty, test the variable directly.

 if (@foo) { ... }
 if (%bar) { ... }

=head2 do SUBROUTINE(LIST)

This form of C<do> to call a subroutine has been deprecated since perl 5, and
is removed in perl v5.20.0.

=head2 POSIX character functions

Several character matching functions in L<POSIX>.pm are deprecated in perl
v5.20.0. See the L<POSIX> documentation for more details. Most uses of these
functions can be replaced with appropriate regex matches.

 isalnum, isalpha, iscntrl, isdigit, isgraph, islower, isprint, ispunct, isspace, issuper, isxdigit

=head2 qw(...) as parentheses

Literal parentheses are required for certain statements such as a
C<for my $foo (...) { ... }> construct. Using a C<qw(...)> list literal without
surrounding parentheses in this syntax is deprecated in perl v5.14.0. Wrap the
literal in parentheses: C<for my $foo (qw(...)) { ... }>.

=head2 UNIVERSAL->import()

The method C<UNIVERSAL->import()> and similarly passing import arguments to
C<use UNIVERSAL> is deprecated in perl v5.12.0 and throws a fatal error in perl
v5.22.0.

=head1 AFFILIATION

This policy is part of L<Perl::Critic::Freenode>.

=head1 CONFIGURATION

This policy is not configurable except for the standard options.

=head1 CAVEATS

This policy is incomplete, as many deprecations are difficult to test for
statically. It is recommended to use L<perlbrew> or L<perl-build> to test your
code under newer versions of Perl, with C<warnings> enabled.

=head1 AUTHOR

Dan Book, C<dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2015, Dan Book.

This library is free software; you may redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Perl::Critic>
