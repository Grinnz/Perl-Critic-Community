package Perl::Critic::Policy::Freenode::DollarAB;

use strict;
use warnings;

use Perl::Critic::Utils qw(:severities :classification :ppi);
use parent 'Perl::Critic::Policy';

our $VERSION = '0.001';

use constant DESC => 'Using $a or $b outside sort()';
use constant EXPL => '$a and $b are reserved variables for usage in sort() and similar functions. Using them in other contexts or "my $a" can lead to strange behavior. Use different variable names.';

sub supported_parameters { () }
sub default_severity { $SEVERITY_HIGH }
sub default_themes { 'freenode' }
sub applies_to { 'PPI::Token::Symbol' }

my %sorters = (
	sort      => 1,
	reduce    => 1,
	pairgrep  => 1,
	pairfirst => 1,
	pairmap   => 1,
);

sub violates {
	my ($self, $elem) = @_;
	return () unless $elem eq '$a' or $elem eq '$b';
	
	my $outer = $elem->parent;
	while ($outer and !$outer->isa('PPI::Structure::Block')) {
		$outer = $outer->parent;
	}
	
	if ($outer and $outer->isa('PPI::Structure::Block')) {
		my $function = $outer->sprevious_sibling;
		if ($function and $function->isa('PPI::Token::Word') and is_function_call $function) {
			my $name = $function;
			$name =~ s/.+:://;
			return () if exists $sorters{$name};
		}
	}
	
	return $self->violation(DESC, EXPL, $elem);
}

1;

=head1 NAME

Perl::Critic::Policy::Freenode::DollarAB

=head1 DESCRIPTION

The special variables C<$a> and C<$b> are reserved for C<sort()> and similar
functions which assign to them to iterate over pairs of values. These are
global variables, and using them outside this context, or especially declaring
them as lexical variables with C<my>, can lead to breakage and strange
behavior. Use different variable names.

  my $a = 1;                  # not ok
  my $abc = 1;                # ok
  sort { $a <=> $b } (3,2,1); # ok

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
