package Tran::Resource::Git;

use warnings;
use strict;
use base qw/Tran::Resource/;
use Tran::Util -common, -debug, -list, -common;
use File::Path qw/make_path/;
use version;
use Time::Piece;
use Furl;
use Web::Query;
use JSON::XS;

sub not_omit_last_name { 1 }

sub get {
  my ($self, $target, $version) = @_;

  $self->fatal("require version for Git resource") if not $version;

  my $original_dir = $self->original_repository->resource_directory;
  my $path = $target;

  $path =~ s{^([a-z]+)\:/+}{$1+};

  $path = path_join $original_dir, $path, $version;
  make_path($path) if ! -d $path;

  qx{git clone --branch $version --depth 1 $target $path};

  $self->info("$target is stored to $path.");

  return(1, $self->target_translation($target), version->new($version));
}

sub target_path {
  my ($self, $target) = @_;
  $target =~ s{^([a-z]+)\:/+}{$1+};
  return $target;
}

sub _config {
  return
    {
     targets => {},
    };
}

=head1 NAME

Tran::Resource::Git - base class for getting git repository

=head1 AUTHOR

Ktat, C<< <ktat at cpan.org> >>

=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2013- Ktat.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Tran

