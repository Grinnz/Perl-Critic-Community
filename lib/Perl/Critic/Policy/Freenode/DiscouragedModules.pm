package Perl::Critic::Policy::Freenode::DiscouragedModules;

use strict;
use warnings;

use Perl::Critic::Utils qw(:severities :classification :ppi);
use Perl::Critic::Violation;
use parent 'Perl::Critic::Policy';

our $VERSION = '0.002';

sub supported_parameters { () }
sub default_severity { $SEVERITY_HIGH }
sub default_themes { 'freenode' }
sub applies_to { 'PPI::Statement::Include' }

my %modules = (
	'AnyEvent' => {
		expl => 'AnyEvent\'s author refuses to use public bugtracking and actively breaks interoperability. See POE, IO::Async, and Mojolicious for sane and interoperable async event loops.',
	},
	'Any::Moose' => {
		expl => 'Any::Moose is deprecated. Use Moo instead.',
	},
	'CGI' => {
		expl => 'CGI.pm is an ancient module for communicating via the CGI protocol, with tons of bad practices and cruft. Use a modern framework such as those based on Plack (Web::Simple, Dancer2, Catalyst) or Mojolicious, they can still be served via CGI if you choose.',
	},
	'Coro' => {
		expl => 'Coro no longer works on perl 5.22, you need to use the author\'s forked version of Perl. Avoid at all costs.',
	},
	'File::Slurp' => {
		expl => 'File::Slurp gets file encodings all wrong, line endings on win32 are messed up, and it was written before layers were properly added. Use File::Slurp::Tiny, File::Slurper, Path::Tiny, Data::Munge, or Mojo::Util.',
	},
	'HTML::Template' => {
		expl => 'HTML::Template is an old and buggy module, try Template Toolkit or HTML::Zoom instead.',
	},
	'JSON' => {
		expl => 'JSON.pm is old and full of slow logic. Use JSON::MaybeXS instead, it is a drop-in replacement in most cases.',
		severity => $SEVERITY_MEDIUM,
	},
	'JSON::Any' => {
		expl => 'JSON::Any is deprecated. Use JSON::MaybeXS instead.',
	},
	'JSON::XS' => {
		expl => 'JSON::XS\'s author refuses to use public bugtracking and actively breaks interoperability. Cpanel::JSON::XS is a fork with several bugfixes and a sane maintainer. See also JSON::MaybeXS.',
	},
	'List::MoreUtils' => {
		expl => 'List::MoreUtils is a far more complex distribution than it needs to be. See List::Util or List::UtilsBy for better options.',
		severity => $SEVERITY_LOW,
	},
	'Mouse' => {
		expl => 'Mouse was created to be a faster version of Moose, a niche that has since been better filled by Moo. Use Moo instead.',
		severity => $SEVERITY_LOW,
	},
	'Net::IRC' => {
		expl => 'Net::IRC is an ancient module implementing the IRC protocol. Use a modern event-loop-based module instead. Choices are POE::Component::IRC (and Bot::BasicBot based on that), Net::Async::IRC, and Mojo::IRC.',
	},
	'XML::Simple' => {
		expl => 'XML::Simple tries to coerce complex XML documents into perl data structures. This leads to overcomplicated structures and unexpected behavior. Use a proper DOM parser instead like XML::LibXML, XML::TreeBuilder, XML::Twig, or Mojo::DOM.',
	},
);

sub _violation {
	my ($self, $module, $elem) = @_;
	my $desc = "Used module $module";
	my $expl = $modules{$module}{expl} // "Module $module is discouraged.";
	my $severity = $modules{$module}{severity} // $self->default_severity;
	return Perl::Critic::Violation->new($desc, $expl, $elem, $severity);
}

sub violates {
	my ($self, $elem) = @_;
	return () unless defined $elem->module and exists $modules{$elem->module};
	return $self->_violation($elem->module, $elem);
}

1;

=head1 NAME

Perl::Critic::Policy::Freenode::DiscouragedModules - Various modules
discouraged from use

=head1 DESCRIPTION

Various modules are discouraged by the denizens of #perl on Freenode IRC, for
various reasons which may include: buggy behavior, cruft, maintainer issues,
or simply better modern replacements.

=head1 MODULES

=head2 AnyEvent

L<AnyEvent>'s author refuses to use public bugtracking and actively breaks
interoperability. See L<POE>, L<IO::Async>, and L<Mojo::IOLoop> for sane and
interoperable async event loops.

=head2 Any::Moose

L<Any::Moose> is deprecated. Use L<Moo> instead.

=head2 CGI

L<CGI>.pm is an ancient module for communicating via the CGI protocol, with
tons of bad practices and cruft. Use a modern framework such as those based on
L<Plack> (L<Web::Simple>, L<Dancer2>, L<Catalyst>) or L<Mojolicious>, they can
still be served via CGI if you choose.

=head2 Coro

L<Coro> no longer works on perl 5.22, you need to use the author's forked
version of Perl. Avoid at all costs.

=head2 File::Slurp

L<File::Slurp> gets file encodings all wrong, line endings on win32 are messed
up, and it was written before layers were properly added. Use
L<File::Slurp::Tiny>, L<File::Slurper>, L<Path::Tiny/"slurp">,
L<Data::Munge/"slurp">, or L<Mojo::Util/"slurp">.

=head2 HTML::Template

L<HTML::Template> is an old and buggy module, try L<Template::Toolkit> or
L<HTML::Zoom> instead.

=head2 JSON

L<JSON>.pm is old and full of slow logic. Use L<JSON::MaybeXS> instead, it is a
drop-in replacement in most cases.

=head2 JSON::Any

L<JSON::Any> is deprecated. Use L<JSON::MaybeXS> instead.

=head2 JSON::XS

L<JSON::XS>'s author refuses to use public bugtracking and actively breaks
interoperability. L<Cpanel::JSON::XS> is a fork with several bugfixes and a
sane maintainer. See also L<JSON::MaybeXS>.

=head2 List::MoreUtils

L<List::MoreUtils> is a far more complex distribution than it needs to be. See
L<List::Util> or L<List::UtilsBy> for better options.

=head2 Mouse

L<Mouse> was created to be a faster version of L<Moose>, a niche that has since
been better filled by L<Moo>. Use L<Moo> instead.

=head2 Net::IRC

L<Net::IRC> is an ancient module implementing the IRC protocol. Use a modern
event-loop-based module instead. Choices are L<POE::Component::IRC> (used for
L<Bot::BasicBot>), L<Net::Async::IRC>, and L<Mojo::IRC>.

=head2 XML::Simple

L<XML::Simple> tries to coerce complex XML documents into perl data structures.
This leads to overcomplicated structures and unexpected behavior. Use a proper
DOM parser instead like L<XML::LibXML>, L<XML::TreeBuilder>, L<XML::Twig>, or
L<Mojo::DOM>.

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
