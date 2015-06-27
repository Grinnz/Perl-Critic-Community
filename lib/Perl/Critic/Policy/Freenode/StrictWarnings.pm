package Perl::Critic::Policy::Freenode::StrictWarnings;

use strict;
use warnings;

use Perl::Critic::Utils qw(:severities :classification :ppi);
use parent 'Perl::Critic::Policy';

use List::Util 'any';

our $VERSION = '0.002';

use constant DESC => 'Missing strict or warnings';
use constant EXPL => 'The strict and warnings pragmas are important to avoid common pitfalls and deprecated/experimental functionality.';

sub supported_parameters { () }
sub default_severity { $SEVERITY_HIGH }
sub default_themes { 'freenode' }
sub applies_to { 'PPI::Document' }

my %importers = (
	'Any::Moose'        => 1,
	'common::sense'     => 1,
	'Modern::Perl'      => 1,
	'Mojo::Base'        => 1,
	'Mojolicious::Lite' => 1,
	'Moo'               => 1,
	'Moo::Role'         => 1,
	'Moose'             => 1,
	'Moose::Exporter'   => 1,
	'Moose::Role'       => 1,
	'Mouse'             => 1,
	'Mouse::Exporter'   => 1,
	'Mouse::Role'       => 1,
	'Mouse::Util'       => 1,
	'strictures'        => 1,
);

sub violates {
	my ($self, $elem) = @_;
	my $includes = $elem->find('PPI::Statement::Include') || [];
	
	# Any of these modules will import strict and warnings to the caller
	return () if any { $_->type//'' eq 'use' and defined $_->module
	                   and exists $importers{$_->module} } @$includes;
	
	my $has_strict = any { $_->pragma eq 'strict'
	                       or ($_->type//'' eq 'use' and $_->version
	                           and $_->version_literal > 5.012) } @$includes;
	return $self->violation(DESC, EXPL, $elem) unless $has_strict;
	
	my $has_warnings = any { $_->pragma eq 'warnings' } @$includes;
	return $self->violation(DESC, EXPL, $elem) unless $has_warnings;
	
	return ();
}

1;

=head1 NAME

Perl::Critic::Policy::Freenode::StrictWarnings - Always use strict and
warnings, or a module that imports these

=head1 DESCRIPTION

The L<strict> and L<warnings> pragmas help avoid many common pitfalls such as
misspellings, scoping issues, and performing operations on undefined values.
Warnings can also alert you to deprecated or experimental functionality. The
pragmas may either be explicitly imported with C<use>, or indirectly through a
number of importer modules such as L<Moose> or L<strictures>. L<strict> is also
enabled automatically with a C<use> declaration of perl version 5.12 or higher.

  use strict;
  use warnings;

  use Moose;

  use 5.012;

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
