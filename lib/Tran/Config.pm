package Tran::Config;

use strict;
use YAML::XS qw/Load Dump/;
use File::Copy qw/copy/;
use Tran::Util -debug, -file;
use File::Slurp qw/slurp/;

sub new {
  my ($self, $file) = @_;
  my $config = {};
  if ($file =~m{\.ya?ml$}) {
    if (-e $file) {
      my $yaml = slurp $file;
      $config = Load($yaml);
    }
  } else {
    Carp::confess("currenty only yaml is supported");
  }
  return bless {config => $config,
                file   => $file,
               } => (ref $self ? ref $self : $self);
}

sub profile {
  my $self = shift;
  $self->{config}{profile};
}

sub resources {
  my ($self, $kind) = @_;
  return $self->{config}{resource} || {};
}

sub default_resource {
  my ($self, $kind) = @_;
  return $self->{config}{default_resource};
}

sub original_repository {
  my ($self) = @_;
  $self->{config}->{repository}->{original} || {};
}

sub translation_repository {
  my ($self, $kind) = @_;
  if (@_ == 2) {
    $self->{config}->{repository}{translation}->{$kind} || {};
  } else {
    $self->{config}->{repository}{translation} || {};
  }
}

sub notify {
 my ($self, $key) = @_;
 if (@_ == 2) {
   $self->{config}->{notify}->{$key};
 } else {
   $self->{config}->{notify} || {};
 }
}

sub save {
  my $self = shift;
  write_file($self->{file}, Dump($self->{config}));
}

1;

=head1 NAME

Tran::Config

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
