package Perl::Critic::Policy::Freenode::WhileDiamondDefaultAssignment;

use strict;
use warnings;

use Perl::Critic::Utils qw(:severities :classification :ppi);
use parent 'Perl::Critic::Policy';

our $VERSION = '0.001';

use constant DESC => '<> operator result not explicitly assigned in while condition';
use constant EXPL => 'When used alone in a while condition, the <> operator assigns its result to $_, but does not localize it. Assign the result to an explicit lexical variable instead (my $line = <...>)';

sub supported_parameters { () }
sub default_severity { $SEVERITY_HIGH }
sub default_themes { 'freenode' }
sub applies_to { 'PPI::Token::Word' }

sub violates {
	my ($self, $elem) = @_;
	return () unless ($elem eq 'while' or $elem eq 'for') and is_perl_bareword $elem;
	
	my $next = $elem->snext_sibling || return ();
	
	# Detect for (;<>;)
	if ($elem eq 'for') {
		return () unless $next->isa('PPI::Structure::For');
		my @statements = grep { $_->isa('PPI::Statement') } $next->children;
		return () unless @statements >= 2;
		my $middle = $statements[1];
		return $self->violation(DESC, EXPL, $elem) if $middle->schildren
			and $middle->schild(0)->isa('PPI::Token::QuoteLike::Readline');
		# Hack because PPI parses this case weirdly
		return $self->violation(DESC, EXPL, $elem) if $middle->schildren >= 3
			and $middle->schild(0) eq '<' and $middle->schild(1)->isa('PPI::Token') and $middle->schild(2) eq '>';
	} elsif ($elem eq 'while') {
		# while (<>) {} or ... while <>
		if ($next->isa('PPI::Structure::Condition')) {
			$next = $next->schild(0);
			return () unless defined $next and $next->isa('PPI::Statement');
			$next = $next->schild(0);
			return $self->violation(DESC, EXPL, $elem)
				if defined $next and $next->isa('PPI::Token::QuoteLike::Readline');
		} else {
			return $self->violation(DESC, EXPL, $elem)
				if $next->isa('PPI::Token::QuoteLike::Readline');
		}
	}
	
	return ();
}

1;

=head1 NAME

Perl::Critic::Policy::Freenode::WhileDiamondDefaultAssignment

=head1 DESCRIPTION

The diamond operator C<E<lt>E<gt>> is extra magical in a while condition: if it
is the only thing in the condition, it will assign its result to C<$_>, but it
does not localize C<$_> to the while loop. (Note, this also applies to a
C<for (;E<lt>E<gt>;)> construct.) This can unintentionally confuse outer loops
that are already using C<$_> to iterate. To avoid this possibility, assign the
result of the diamond operator to an explicit lexical variable.

  while (<$fh>) { ... }            # not ok
  ... while <STDIN>;               # not ok
  for (;<>;) { ... }               # not ok
  while (my $line = <$fh>) { ... } # ok
  ... while $line = <STDIN>;       # ok
  for (;my $line = <>;) { ... }    # ok

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
