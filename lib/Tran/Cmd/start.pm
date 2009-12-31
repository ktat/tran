package Tran::Cmd::start;

use warnings;
use strict;
use Tran::Cmd -command;
use Tran;
use Tran::Util -base, -debug;
use File::Path qw/make_path/;

sub abstract {  'start new translation'; }

sub run {
  my ($self, $opt, $args) = @_;
  my ($resource, $target, $version) = @$args;

  my $tran = $self->app->tran;
  my $r = $tran->resource($resource);
  my @result = $r->get($target, $version);
  if (@result == 3) {
    if (defined $version and $version) {
      $self->info("You have $target($result[2]) (original)");
    } else {
      $self->info("You have the latest version($result[2]) of $target (original)");
    }
  } else {
    $version ||= '';
    $self->info("Got $target $version");
  }
  my($target_path, $translation_name, $files);
  ($target_path, $translation_name, $version, $files) = @result; # version, files, translation

  my $translation = $tran->translation($translation_name) or $self->fatal("maybe bad name: $translation_name");
  my $original    = $translation->original_repository;

  unless ($translation->has_version($target_path, $version)) {
    my $prev_version = $original->prev_version($target_path) || $original->latest_version($target_path);
    if ($prev_version < $version) {
      if ($translation->has_version($target_path, $prev_version)) {
        $translation->merge($target_path, $prev_version, $version);
        $self->info("copy previous version($prev_version) to new version($version) with patch.");
      } else {
        $self->info("translation for $prev_version is not found.");
      }
    } else {
      $translation->copy_from_original($target_path, $version);
      $self->info("copy original files to translation path.");
    }
    $translation->update_version_info($target_path, $version);
  } else {
    $self->info("translation files for $target $version are found.");
  }
}

sub usage_desc {
  return 'tran start RESOURCE TARGET [VERSION]';
}

sub validate_args {
  my ($self, $opt, $args) = @_;
  $self->usage_error("arguments are not enough.")  if @$args < 2;
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
