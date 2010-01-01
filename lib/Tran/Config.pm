package Tran::Config;

use strict;
use YAML::XS qw/Load Dump/;
use File::Copy qw/copy/;
use Util::Any -debug;
use File::Slurp qw/slurp/;

sub new {
  my ($self, $file) = @_;
  my $config = {};
  if ($file =~m{\.ya?ml$} and -e $file) {
    my $yaml = slurp $file;
    $config = Load($yaml);
  } else {
    die "currenty only yaml is supported";
  }
  return bless {config => $config,
                file   => $file,
               } => (ref $self ? ref $self : $self);
}

sub resources {
  my ($self, $kind) = @_;
  return $self->{config}{resources};
}

sub original_repository {
  my ($self) = @_;
  $self->{config}->{repository}->{original};
}

sub translation_repository {
  my ($self, $kind) = @_;
  if (@_ == 2) {
    $self->{config}->{repository}{translation}->{$kind} || {};
  } else {
    $self->{config}->{repository}{translation};
  }
}

sub set_original {
  my ($self, $kind, $r) = @_;
  $self->{config}->{original}->{$kind} = $r;
}

sub set_translation {
  my ($self, $kind, $r) = @_;
  $self->{config}->{translation}->{$kind} = $r;
}

sub notify {
 my ($self, $key) = @_;
 if (@_ == 2) {
   $self->{config}->{notify}->{$key};
 } else {
   $self->{config}->{notify};
 }
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
