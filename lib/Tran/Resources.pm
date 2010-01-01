package Tran::Resources;

use warnings;
use strict;
use Tran::Util -base, -debug;

sub new {
  my ($class, %self) = @_;
  my $target = $self{config}->{targets};
#  my %target;
#  foreach my $name (keys %$target) {
#    $target{$name} = Tran::Resources::Target->new($target->{$name} || {});
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

sub root_config {
  my $self = shift;
  return $self->{root}{config};
}

sub root {
  my $self = shift;
  return $self->{root};
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

Tran::Resources

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
