package Tran::Repository;

use warnings;
use strict;
use version;
use Tran::Util -file => ['find'], -base;

sub new {
  my ($class, %self) = @_;
  bless \%self => $class;
}

sub type {
  my ($self) = @_;
  $self->{config}->{type};
}

sub place {
  my $self = shift;
  $self->{config}->{place};
}

sub directory {
  my $self = shift;
  $self->{config}->{directory};
}

sub reset {
  my $self = shift;
  delete $self->{versions};
}

sub get_versions {
  my ($self, $name) = @_;
  die if @_ != 2;
  return if exists $self->{versions}->{$name};

  my @versions;
  if (opendir my $d, $self->directory . '/' . $name) {
    foreach my $version (grep /^[\d\.]+$/, readdir $d) {
      push @versions, version->new($version);
    }
    closedir $d;
  } else {
    $self->debug(sprintf "directory is not found : %s/%s", $self->directory, $name);
  }
  return $self->{versions}->{$name} = [sort {$a cmp $b} @versions];
}

sub latest_version {
  my ($self, $name) = @_;
  die if @_ != 2;
  $self->get_versions($name);

  return $self->{versions}->{$name}->[-1];
}

sub has_version {
  my ($self, $name, $version) = @_;
  die if @_ != 3;
  $self->get_versions($name);

  foreach my $ver (@{$self->{versions}->{$name}}) {
    return 1 if $ver eq $version;
  }
  return 0;
}

sub prev_version {
  my ($self, $name) = @_;
  die "not enough argument." if @_ != 2;
  $self->get_versions($name);
  return $self->{versions}->{$name}->[-2];
}

sub path_format {
  my $self = shift;
  return $self->{config}{path_format};
}

sub path_of {
  my ($self, $target, $version) = @_;
  my $path = join "/", $self->directory,
    $self->path_format ? sprintf($self->path_format, $target, $version): ($target, $version);
  $path =~s{//}{/};
  return $path;
}

sub files {
  my ($self, $target, $version) = @_;
  my $dir = quotemeta($self->path_of($target, $version));
  my @files;
  find({wanted => sub {push @files, $_}, no_chdir => 1}, $self->path_of($target, $version));
  return grep {s{^$dir}{}} @files;
}

1;

=head1 NAME

Tran::Repository

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
