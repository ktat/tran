package Tran::Resources::Target;

use strict;

sub new {
  my ($class, $config) = @_;
  my %version;
  @version{@{$config->{versions} || []}} = ();
  bless {version => \%version, translation => $config->{translation}}
}

sub has_version {
  my ($self, $version) = @_;
  return exists $self->{version}->{$version} || 0;
}

sub translation {
  my $self = shift;
  return $self->{translation};
}

1;

=head1 NAME

Tran::

=head1 AUTHOR

Ktat, C<< <ktat at cpan.org> >>

=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2010 Ktat.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Tran
