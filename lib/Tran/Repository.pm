package Tran::Repository;

use warnings;
use strict;
use version;
use Carp qw/confess/;
use Tran::Util -file => ['find'], -common;

sub new {
  my ($class, %self) = @_;
  bless \%self => $class;
}

sub name {
  my $self = shift;
  $self->{name};
}

sub type {
  my $self = shift;
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

sub get_versions { confess "get_versions must be implemented in sub class: " . ref $_[0]; }

sub latest_version {
  my ($self, $target) = @_;
  die if @_ != 2;

  my $name = $self->target_path($target);
  $self->get_versions($target);

  return $self->{versions}->{$name}->[-1];
}

sub target_path {
  my ($self, $target) = @_;
  Carp::croak("taget name is required") if @_ == 1;
  $target =~s{::}{\-}g;
  return $target;
}

sub has_target { confess "has_target must be implemented it in subclass: " . ref $_[0]; }

sub has_version {
  my ($self, $target, $version) = @_;
  die if @_ != 3;
  my $name = $self->target_path($target);
  $self->get_versions($target);
  foreach my $ver (@{$self->{versions}->{$name}}) {
    return 1 if $ver eq $version;
  }
  return 0;
}

sub prev_version {
  my ($self, $target) = @_;
  my $name = $self->target_path($target);
  die "not enough argument." if @_ != 2;
  $self->get_versions($target);
  return $self->{versions}->{$name}->[-2] || 0;
}

sub path_format { '' }

sub path_of {
  my ($self, $target, $version) = @_;
  $version ||= $self->latest_version($target);
  my $target_path = $self->target_path($target);
  my $path = $self->directory;
  my $path_format = $self->path_format;
  if (defined $path_format and not $path_format) {
    $path = path_join $path, $target_path, $version;
  } elsif (defined $path_format) {
    $path_format =~s{%n}{$target_path};
    $path_format =~s{%v}{$version};
    $path = path_join $path, $path_format;
  }
  return $path;
}

sub files {
  my ($self, $target, $version) = @_;
  my $path = $self->path_of($target, $version);
  my $dir = quotemeta($path);
  my @files;
  find({wanted => sub {push @files, $_}, no_chdir => 1}, $path);
  return grep {s{^$dir}{}} @files;
}

1;

=head1 NAME

Tran::Repository - base class for repository.

=head1 DESCRIPTION

see Tran::Manual::Extend

=head1 METHODS

=head2 new

=head2 name

=head2 type

=head2 place

=head2 directory

=head2 reset

=head2 get_versions

=head2 latest_version

=head2 target_path

=head2 has_target

=head2 has_version

=head2 prev_version

=head2 path_format

=head2 path_of

 $repo->path_of($target, $version);

It returns target directory in the repository.
This method's behavior is depend on C<path_format>.

=over 4

=item path_format returns undef

returns repositorry's directory.

=item path_format returns empty string

if target name is 'AAA::BBB', it retunrs:

 /path/to/repository/directory/AAA-BBB

=item path_format returns string

If string has %n and/or %v, it/they is/are replaced.

 %n ... target name
 %v ... version

So, if string is '%n-%v' and target name is 'AAA::BBB' and version is "0.01",
it returns:

 /path/to/repository/directory/AAA-BBB-0.01

=back

=head2 files

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
