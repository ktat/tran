package Tran::Cmd::start;

use warnings;
use strict;
use Tran::Cmd -command;
use Tran;
use Tran::Util -common, -debug, -string;
use File::Path qw/make_path/;
use IO::Prompt;

sub abstract { 'start new translation'; }

sub opt_spec {
  return (
          ['resource|r=s', "resource. required." ],
          ['force|f'   , "forcely start translation even if translation exists" ],
         );
}

sub run {
  my ($self, $opt, $args) = @_;
  my ($target, $version, @rest) = @$args;
  my $resource = $opt->{resource};

  my($translation_name, $files);
  ($translation_name, $version, $files) = $self->Tran::Cmd::get::run({resource => $resource}, $args);

  my $tran = $self->app->tran;

  $self->debug("translation_name: $translation_name");

  my $translation = $tran->translation($translation_name) or $self->fatal("maybe bad name: $translation_name");
  my $original    = $translation->original_repository;

  if ( not my $already = $translation->has_version($target, $version) or $opt->{force}) {
    if ($already) {
      $self->info("forcely start translation.");
    }
    if ($translation->vcs) {
      if ($translation->has_target($target)) {
        $self->app->prompt("you want to update in your working directory with VCS?")
          and $translation->vcs->update($translation->path_of($target, $version))
            and $self->info("vcs: update $target");
      } elsif ($translation->vcs->can('checkout_target')) {
        $self->app->prompt("you want to checkout in your working directory with VCS?")
          and $translation->vcs->checkout_target($translation->target_path($target), $version)
            and $self->info("vcs: checkout $target");
      }
    }
    my $prev_version = $original->prev_version($target) || $original->latest_version($target);
    my $want_merge = 0;
    if ($prev_version < $version) {
      $want_merge = $self->app->prompt("you want to merge with previous version?");
    }
    if ($want_merge) {
      if ($translation->has_version($target, $prev_version)) {
        $translation->merge($target, $prev_version, $version);
        $self->info("copy previous version($prev_version) to new version($version) with patch.");
      } else {
        $self->debug("translation for $prev_version is not found.");
        $translation->copy_from_original($target, $version);
        $self->info("copy original files to translation path.");
      }
    } else {
      $translation->copy_from_original($target, $version);
      $self->info("copy original files to translation path.");
    }
    $translation->update_version_info($target, $version);
    if ($translation->vcs) {
      if ($self->app->prompt("add files and commit to VCS ?")) {
        $translation->vcs->add_files($translation->path_of($target, $version));
        $self->info("vcs: add files and commit");
      }
    }
    if ($translation->notify and $self->app->prompt("notify?")) {
      $tran->notify($translation->notify, 'start', $target, $version);
    }
  } else {
    $self->info("translation files for $target $version are found.");
  }
}

sub usage_desc {
  return 'tran start -r RESOURCE TARGET [VERSION/URL]';
}

sub validate_args {
  shift()->Tran::Cmd::_validate_args_resource(@_, 1);
}

1;

=head1 NAME

Tran::Cmd::start

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
