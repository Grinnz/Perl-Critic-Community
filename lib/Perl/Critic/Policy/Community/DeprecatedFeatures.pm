package Perl::Critic::Policy::Community::DeprecatedFeatures;

use strict;
use warnings;

use List::Util 'any', 'none';
use Perl::Critic::Utils qw(:severities :classification :ppi);
use parent 'Perl::Critic::Policy';

our $VERSION = 'v1.0.4';

sub supported_parameters { () }
sub default_severity { $SEVERITY_HIGH }
sub default_themes { 'community' }
sub applies_to { 'PPI::Element' }

my %features = (
	':=' => 'Use of := as an empty attribute list is deprecated in perl v5.12.0, use = alone.',
	'$[' => 'Use of $[ is deprecated in perl v5.12.0. See Array::Base and String::Base.',
	'/\\C/' => 'Use of the \\C character class in regular expressions is deprecated in perl v5.20.0. To examine a string\'s UTF-8-encoded byte representation, encode it to UTF-8.',
	'?PATTERN?' => 'Use of ? as a match regex delimiter without an initial m is deprecated in perl v5.14.0. Use m?PATTERN? instead.',
	'autoderef' => 'Use of each/keys/pop/push/shift/splice/unshift/values on a reference is an experimental feature that is removed in perl v5.24.0. Dereference the array or hash to use these functions on it.',
	'Bare here-doc' => 'Use of bare << to create a here-doc with an empty string terminator is deprecated in perl 5. Use a quoted empty string like <<\'\'.',
	'chdir(\'\')' => 'Use of chdir(\'\') or chdir(undef) to chdir home is deprecated in perl v5.8.0. Use chdir() instead.',
	'defined on array/hash' => 'Use of defined() on an array or hash is deprecated in perl v5.6.2. The array or hash can be tested directly to check for non-emptiness: if (@foo) { ... }',
	'do SUBROUTINE(LIST)' => 'Use of do to call a subroutine is deprecated in perl 5.',
	'NBSP in \\N{...}' => 'Use of the "no-break space" character in character names is deprecated in perl v5.22.0.',
	'POSIX character function' => 'Several character matching functions in POSIX.pm are deprecated in perl v5.20.0: isalnum, isalpha, iscntrl, isdigit, isgraph, islower, isprint, ispunct, isspace, isupper, and isxdigit. Regular expressions are a more portable and correct way to test character strings.',
	'POSIX::tmpnam()' => 'The tmpnam() function from POSIX is deprecated in perl v5.22.0. Use File::Temp instead.',
	'qw(...) as parentheses' => 'Use of qw(...) as parentheses is deprecated in perl v5.14.0. Wrap the list in literal parentheses when required, such as in a foreach loop.',
	'require ::Foo::Bar' => 'Bareword require starting with a double colon is an error in perl v5.26.0.',
	'UNIVERSAL->import()' => 'The method UNIVERSAL->import() (or passing import arguments to "use UNIVERSAL") is deprecated in perl v5.12.0.',
);

my %posix_deprecated = map { ($_ => 1, "POSIX::$_" => 1) }
	qw(isalnum isalpha iscntrl isdigit isgraph islower isprint ispunct isspace isupper isxdigit);

my %autoderef_functions = map { ($_ => 1) }
	qw(each keys pop push shift splice unshift values);

sub _violation {
	my ($self, $feature, $elem) = @_;
	my $desc = "$feature is deprecated";
	my $expl = $features{$feature} // "$feature is deprecated or removed from recent versions of Perl.";
	return $self->violation($desc, $expl, $elem);
}

sub violates {
	my ($self, $elem) = @_;
	my $next;
	my $prev;
	my $parent;
	my @args;
	my @violations;
	if ($elem->isa('PPI::Statement')) {
		if ($elem->isa('PPI::Statement::Include')) {
			# use UNIVERSAL ...;
			if ($elem->type eq 'use' and defined $elem->module and $elem->module eq 'UNIVERSAL') {
				my @args = $elem->arguments;
				if (!@args or !$args[0]->isa('PPI::Structure::List') or $args[0]->schildren) {
					push @violations, $self->_violation('UNIVERSAL->import()', $elem);
				}
			}
			# require ::Foo::Bar
			if (defined $elem->module and $elem->module =~ m/^::/) {
				push @violations, $self->_violation('require ::Foo::Bar', $elem);
			}
		}
	} elsif ($elem->isa('PPI::Token')) {
		if ($elem->isa('PPI::Token::Symbol')) {
			# $[
			if ($elem eq '$[') {
				push @violations, $self->_violation('$[', $elem);
			}
		} elsif ($elem->isa('PPI::Token::Operator')) {
			# :=
			if ($elem eq ':' and $next = $elem->next_sibling and $next->isa('PPI::Token::Operator') and $next eq '=') {
				push @violations, $self->_violation(':=', $elem);
			# ?PATTERN? - PPI parses this as multiple ? operators
			} elsif ($elem eq '?' and $parent = $elem->parent and $parent->isa('PPI::Statement')) {
				$next = $elem->snext_sibling;
				until (!$next or ($next->isa('PPI::Token::Operator') and $next eq '?')) {
					$next = $next->snext_sibling;
				}
				# If the statement has a : operator, this is probably a ternary operator.
				# PPI also tends to detect the : as a loop label.
				if ($next and none { ($_->isa('PPI::Token::Operator') and $_ eq ':') or $_->isa('PPI::Token::Label') } $parent->schildren) {
					push @violations, $self->_violation('?PATTERN?', $elem);
				}
			# Bare here-doc - differentiate this from the legitimate << operator
			} elsif ($elem eq '<<' and (!($next = $elem->snext_sibling)
				or ($next->isa('PPI::Token::Operator') and $next ne '~' and $next ne '!' and $next ne '+' and $next ne '-')
				or ($next->isa('PPI::Token::Structure') and $next ne '(' and $next ne '{' and $next ne '['))) {
				push @violations, $self->_violation('Bare here-doc', $elem);
			}
		} elsif ($elem->isa('PPI::Token::Word')) {
			# UNIVERSAL->import()
			if ($elem eq 'UNIVERSAL'
		        and $next = $elem->snext_sibling and $next->isa('PPI::Token::Operator') and $next eq '->'
		        and $next = $next->snext_sibling and $next->isa('PPI::Token::Word') and $next eq 'import') {
				push @violations, $self->_violation('UNIVERSAL->import()', $next);
			# for $x qw(...)
			} elsif (($elem eq 'for' or $elem eq 'foreach') and !$elem->sprevious_sibling) {
				$next = $elem->snext_sibling;
				until (!$next or $next->isa('PPI::Structure::List')
				       or $next->isa('PPI::Token::QuoteLike::Words')) {
					$next = $next->snext_sibling;
				}
				if ($next and $next->isa('PPI::Token::QuoteLike::Words')) {
					push @violations, $self->_violation('qw(...) as parentheses', $next);
				}
			# do SUBROUTINE(LIST)
			} elsif ($elem eq 'do' and $next = $elem->snext_sibling) {
				if ((($next->isa('PPI::Token::Word') and is_function_call $next)
				    or ($next->isa('PPI::Token::Symbol') and ($next->raw_type eq '&' or $next->raw_type eq '$')))
				    and ($next = $next->snext_sibling and $next->isa('PPI::Structure::List'))) {
					push @violations, $self->_violation('do SUBROUTINE(LIST)', $elem);
				}
			# avoid false positives for method calls
			} elsif (!($prev = $elem->sprevious_sibling) or !$prev->isa('PPI::Token::Operator') or $prev ne '->') {
				# POSIX character function or POSIX::tmpnam()
				if (exists $posix_deprecated{$elem} or $elem eq 'tmpnam' or $elem eq 'POSIX::tmpnam') {
					my $is_posix = $elem =~ m/^POSIX::/ ? 1 : 0;
					(my $function_name = $elem) =~ s/^POSIX:://;
					unless ($is_posix) {
						my $includes = $elem->document->find('PPI::Statement::Include') || [];
						foreach my $stmt (grep { ($_->module // '') eq 'POSIX' } @$includes) {
							my @args = $stmt->arguments;
							$is_posix = 1 if !@args or any { $_ =~ m/\b\Q$function_name\E\b/ } @args;
						}
					}
					if ($is_posix) {
						push @violations, $self->_violation('POSIX::tmpnam()', $elem) if $function_name eq 'tmpnam';
						push @violations, $self->_violation('POSIX character function', $elem) if exists $posix_deprecated{$elem};
					}
				# defined array/hash
				} elsif ($elem eq 'defined' and $next = $elem->snext_sibling) {
					$next = $next->schild(0) if $next->isa('PPI::Structure::List');
					if ($next and $next->isa('PPI::Token::Symbol')
					    and ($next->raw_type eq '@' or $next->raw_type eq '%')
					    and $next->raw_type eq $next->symbol_type) {
						push @violations, $self->_violation('defined on array/hash', $elem);
					}
				# autoderef
				} elsif (exists $autoderef_functions{$elem} and $next = $elem->snext_sibling) {
					$next = $next->schild(0) if $next->isa('PPI::Structure::List');
					$next = $next->schild(0) if $next and $next->isa('PPI::Statement::Expression');
					if ($next and $next->isa('PPI::Token::Symbol') and $next->raw_type eq '$') {
						my $is_postderef;
						until (!$next or ($next->isa('PPI::Token::Structure') and $next eq ';')
							or ($next->isa('PPI::Token::Operator') and $next eq ',')) {
							$next = $next->snext_sibling;
							if ($next and $next->isa('PPI::Token::Cast') and ($next eq '@*' or $next eq '%*')) {
								$is_postderef = 1;
								last;
							}
						}
						push @violations, $self->_violation('autoderef', $elem) unless $is_postderef;
					}
				} elsif ($elem eq 'chdir' and $next = $elem->snext_sibling) {
					$next = $next->schild(0) if $next->isa('PPI::Structure::List');
					$next = $next->schild(0) if $next and $next->isa('PPI::Statement::Expression');
					if ($next and (($next->isa('PPI::Token::Quote') and !length $next->string)
						or ($next->isa('PPI::Token::Word') and $next eq 'undef'))) {
						push @violations, $self->_violation('chdir(\'\')', $elem);
					}
				}
			}
		} elsif ($elem->isa('PPI::Token::Regexp')) {
			# ?PATTERN?
			if ($elem->isa('PPI::Token::Regexp::Match') and ($elem->get_delimiters)[0] eq '??' and $elem !~ m/^m/) {
				push @violations, $self->_violation('?PATTERN?', $elem);
			}
			if (!$elem->isa('PPI::Token::Regexp::Transliterate')) {
				push @violations, $self->_violates_interpolated($elem);
			}
		} elsif ($elem->isa('PPI::Token::HereDoc')) {
			# Bare here-doc
			if ($elem eq '<<') {
				push @violations, $self->_violation('Bare here-doc', $elem);
			}
		} elsif ($elem->isa('PPI::Token::QuoteLike')) {
			if ($elem->isa('PPI::Token::QuoteLike::Regexp') or $elem->isa('PPI::Token::QuoteLike::Backtick') or $elem->isa('PPI::Token::QuoteLike::Command')) {
				push @violations, $self->_violates_interpolated($elem);
			}
		} elsif ($elem->isa('PPI::Token::Quote')) {
			if ($elem->isa('PPI::Token::Quote::Double') or $elem->isa('PPI::Token::Quote::Interpolate')) {
				push @violations, $self->_violates_interpolated($elem);
			}
		}
	}
	return @violations;
}

sub _violates_interpolated {
	my ($self, $elem) = @_;
	my @violations;
	# NBSP in \N{...}
	my $contents;
	if ($elem->isa('PPI::Token::Regexp') or $elem->isa('PPI::Token::QuoteLike::Regexp')) {
		$contents = $elem->get_match_string;
		# /\C/
		push @violations, $self->_violation('/\\C/', $elem) if $contents =~ m/(?<!\\)\\C/;
	} elsif ($elem->isa('PPI::Token::Quote')) {
		$contents = $elem->string;
	} else {
		# Backticks and qx elements have no contents method
		$contents = $elem;
	}
	push @violations, $self->_violation('NBSP in \\N{...}', $elem) if $contents =~ m/\\N\{[^}]*\x{a0}[^}]*\}/;
	return @violations;
}

1;

=head1 NAME

Perl::Critic::Policy::Community::DeprecatedFeatures - Avoid features that have
been deprecated or removed from Perl

=head1 DESCRIPTION

While L<Perl::Critic::Policy::Community::StrictWarnings> will expose usage of
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

=head2 /\C/

The C<\C> regular expression character class would match a single byte of the
internal representation of the string, which was dangerous because it violated
the logical character abstraction of Perl strings, and substitutions using it
could result in malformed UTF-8 sequences. It was deprecated in perl v5.20.0
and removed in perl v5.24.0. Instead, explicitly encode the string to UTF-8
using L<Encode> to examine its UTF-8-encoded byte representation.

=head2 ?PATTERN?

The C<?PATTERN?> regex match syntax is deprecated in perl v5.14.0 and removed
in perl v5.22.0. Use C<m?PATTERN?> instead.

=head2 autoderef

An experimental feature was introduced in perl v5.14.0 to allow calling various
builtin functions (which operate on arrays or hashes) on a reference, which
would automatically dereference the operand. This led to ambiguity when passed
objects that overload both array and hash dereferencing, and so was removed in
perl v5.24.0. Instead, explicitly dereference the reference when calling these
functions. The functions affected are C<each>, C<keys>, C<pop>, C<push>,
C<shift>, C<splice>, C<unshift>, and C<values>.

=head2 Bare here-doc

Using C< << > to initiate a here-doc would create it with an empty terminator,
similar to C< <<'' >, so the here-doc would terminate on the next empty line.
Omitting the quoted empty string has been deprecated since perl 5, and is a
fatal error in perl v5.28.0.

=head2 chdir('')

Passing an empty string or C<undef> to C<chdir()> would change to the home
directory, but this usage is deprecated in perl v5.8.0 and throws an error in
perl v5.24.0. Instead, call C<chdir()> with no arguments for this behavior.

=head2 defined on array/hash

Using the function C<defined()> on an array or hash probably does not do what
you expected, and is deprecated in perl v5.6.2 and throws a fatal error in perl
v5.22.0. To check if an array or hash is non-empty, test if it has elements.

 if (@foo) { ... }
 if (keys %bar) { ... }

=head2 do SUBROUTINE(LIST)

This form of C<do> to call a subroutine has been deprecated since perl 5, and
is removed in perl v5.20.0.

=head2 NBSP in \N{...}

Use of the "no-break space" character in L<character names|charnames> is
deprecated in perl v5.22.0 and an error in perl v5.26.0.

=head2 POSIX character functions

Several character matching functions in L<POSIX>.pm are deprecated in perl
v5.20.0. See the L<POSIX> documentation for more details. Most uses of these
functions can be replaced with appropriate regex matches.

 isalnum, isalpha, iscntrl, isdigit, isgraph, islower, isprint, ispunct, isspace, issuper, isxdigit

=head2 POSIX::tmpnam()

The C<tmpnam()> function from L<POSIX>.pm is deprecated in perl v5.22.0 and
removed in perl v5.26.0. Use L<File::Temp> instead.

=head2 qw(...) as parentheses

Literal parentheses are required for certain statements such as a
C<for my $foo (...) { ... }> construct. Using a C<qw(...)> list literal without
surrounding parentheses in this syntax is deprecated in perl v5.14.0 and a
syntax error in perl v5.18.0. Wrap the literal in parentheses:
C<for my $foo (qw(...)) { ... }>.

=head2 require ::Foo::Bar

A bareword C<require> (or C<use>) starting with a double colon would
inadvertently translate to a path starting with C</>. Starting in perl v5.26.0,
this is a fatal error.

=head2 UNIVERSAL->import()

The method C<< UNIVERSAL->import() >> and similarly passing import arguments to
C<use UNIVERSAL> is deprecated in perl v5.12.0 and throws a fatal error in perl
v5.22.0. Calling C<use UNIVERSAL> with no arguments is not an error, but serves
no purpose.

=head1 AFFILIATION

This policy is part of L<Perl::Critic::Community>.

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
