package Perl::Critic::Policy::Freenode::ArrayAssignAref;

use strict;
use warnings;

use parent 'Perl::Critic::Policy::Community::ArrayAssignAref';

our $VERSION = 'v1.0.4';

sub default_themes { 'freenode' }

1;

=head1 NAME

Perl::Critic::Policy::Freenode::ArrayAssignAref - Don't assign an anonymous
arrayref to an array

=head1 DESCRIPTION

Legacy C<freenode> theme policy alias.

=head1 POLICY MOVED

This policy has been moved to L<Perl::Critic::Community>.

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

L<Perl::Critic>, L<Perl::Critic::Community>
