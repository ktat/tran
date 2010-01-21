package Tran::Resource;

use warnings;
use strict;
use Tran::Util -common, -debug;

sub new {
  my ($class, %self) = @_;
  my $target = $self{config}->{targets};
#  my %target;
#  foreach my $name (keys %$target) {
#    $target{$name} = Tran::Resource::Target->new($target->{$name} || {});
#    # $target{$name}->versions($self->root->original_repository->get_versions($name))
#  }
  $self{targets} = $target;
  bless \%self, $class;
}

sub get {
  # getting target in resource
  die;
}

sub config {
  my $self = shift;
  return $self->{config};
}

sub targets {
  my $self = shift;
  return $self->{targets};
}

sub translation {
  my $self = shift;
  $self->config->{translation};
}

sub original_repository {
  my $self = shift;
  $self->{original};
}

sub target_translation {
  my ($self, $target) = @_;
  my $t = $self->targets->{$target};
  if (defined $t) {
    return $t->{translation} || $self->translation;
  } else {
    return $self->translation;
  }
}

1;

=head1 NAME

Tran::Resource - base class for resource.

=head1 DESCRIPTION

see Tran::Manual::Extend

=head1 METHODS

=head2 new

=head2 get

=head2 config

=head2 targets

=head2 translation

=head2 original_repository

=head2 target_translation

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
