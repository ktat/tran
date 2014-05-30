package Tran::Resource;

use warnings;
use strict;
use Carp qw/confess/;
use Tran::Util -common, -debug, -string;
use File::Spec qw/path_join/;

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

sub name {
  my ($self) = @_;
  my $name = ref $self;
  $name =~ s{^Tran::Resource::}{};
  decamelize $name;
}

sub get {
  # getting target in resource
  die;
}

sub has_target {
  my ($self, $target) = @_;
  return $self->original_repository->has_target($target);
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
  confess("Configuration may be wrong(no targets).") if not $self->targets and not $self->translation;
  if (defined $target and my $t = $self->targets->{$target}) {
    return $t->{translation} || $self->translation;
  } else {
    return $self->translation;
  }
}

sub not_omit_last_name { 0 }

sub find_target_resource {
  my ($self, $target) = @_;
  my $resource;
  if (not $self->has_target($target)) {
    my $resource_found = 0;
    my $tran = $self->{tran};

    foreach my $r (keys %{$self->{tran}->resources}) {
      next if camelize $r eq ref $self;

      $resource = $tran->resource($r);
      if ($resource->has_target($target)) {
	$resource_found = 1;
	last;
      }
    }
    if (not $resource_found) {
      $self->fatal("$target is not in any resource");
    }
  }
  return $resource;
}

sub find_translation_repository {
  my ($self, $target) = @_;
  my $tran = $self->{tran};
  return $tran->translation_repository($tran->get_sticked_translation($target, $self->name || $self->target_translation($target)));
}

1;

=head1 NAME

Tran::Resource - base class for resource.

=head1 DESCRIPTION

see Tran::Manual::Extend

=head1 METHODS

=head2 new

=head2 name

=head2 get

=head2 config

=head2 targets

=head2 translation

=head2 has_target

=head2 original_repository

=head2 target_translation

 $resoruce->target_translation($target);

=head2 not_omit_last_name

=head2 find_target_resource

 $resoruce->find_resource($target);

=head2 find_translation_repository

 $resoruce->find_translation_repository($target);

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
