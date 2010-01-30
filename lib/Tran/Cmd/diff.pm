package Tran::Cmd::diff;
use lib qw(../../);
use warnings;
use strict;
use Tran::Cmd -command;
use Tran;
use Tran::Util -common, -debug, -string;
use Text::Diff ();
use File::Find qw/find/;

sub abstract {  'show diffrence'; }

sub opt_spec {
  return (
          ['translation|t', "show difference from translation repository" ],
          ['original|o', "show difference from original repository" ],
          ['version|v=s', "old_version / old_version:new_version" ],
         );
}

sub run {
  my ($self, $opt, $args) = @_;
  my ($resource_name, $target, @files) = @$args;
  my ($version1, $version2) = split(/:/, $opt->{version} || '', 2);

  $| = 1;
  my $tran = $self->app->tran;
  my $resource = $tran->resource(camelize $resource_name);
  my ($old_path, $new_path);
  my $translation = $tran->translation($resource->target_translation($target));
  my $mode = 0;
  if ($opt->{translation}) {
    $mode = 1;
    $old_path = $translation->path_of($target, $version1 ||= $translation->prev_version($target));
    $new_path = $translation->path_of($target, $version2 ||= $translation->latest_version($target));
    $self->debug("diff between translation $version1 and translation $version2");
    $self->_diff($mode, $translation, $old_path, {}, $new_path, {}, \@files);
  } elsif ($opt->{original}) {
    $mode = 2;
    my $copy_option = $translation->copy_option;
    my $original = $resource->original_repository;
    $old_path = $original->path_of($target, $version1 ||= $original->prev_version($target));
    $new_path = $original->path_of($target, $version2 ||= $original->latest_version($target));
    $self->debug("diff between original $version1 and original $version2");
    $self->_diff($mode, $translation, $old_path, $copy_option, $new_path, $copy_option, \@files);
  } else {
    my $original = $resource->original_repository;
    my $copy_option = $translation->copy_option;
    $old_path = $original->path_of($target   , $version1 ||= $original->latest_version($target));
    $new_path = $translation->path_of($target, $version2 ||= $translation->latest_version($target));
    $self->debug("diff between original $version1 and translation $version2");
    $self->_diff($mode, $translation, $old_path, $copy_option, $new_path, {}, \@files);
  }
}

sub _diff {
  my ($self, $mode, $translation, $old_path, $old_option, $new_path, $new_option, $files) = @_;

  $self->fatal("missing old_path: $old_path") unless -d $old_path;
  $self->fatal("missing new_path: $new_path") unless -d $new_path;

  my $wanted;
  my $enc = $translation->encoding;
  my $out;
  if ($ENV{TRAN_PAGER}) {
    open $out, "|-", $ENV{TRAN_PAGER} or $self->fatal("cannot open '$ENV{TRAN_PAGER}' with mode '|-'");
  } else {
    $out = *STDOUT;
  }
  if ($mode == 1) { # -t
    # translation and translation
    $wanted = sub {
      if (-f $File::Find::name and $File::Find::name !~ m{/CVS/}) {
        my $old_file = $File::Find::name;
        my $old_content = encoding_slurp($old_file, $enc) or return;

        my $new_file = $old_file;
        $new_file =~s{^$old_path}{$new_path};
        my $new_content = encoding_slurp($new_file, $enc) or return;
        if (my $diff = Text::Diff::diff(\$old_content, \$new_content)) {
          print $out "--- $old_file\n+++ $new_file\n$diff\n\n";
        }
      }
    }
  } elsif ($mode == 2) { # -o
    # original vs original
    $wanted = sub {
      if (-f $File::Find::name) {
        my $old_file = $File::Find::name;
        my ($result, $_old_file, $old_content)
          = $translation->_apply_copy_option($old_file, $old_option, $old_path, $new_path);
        return if not $result;
        my $new_file = $old_file;
        $new_file =~s{^$old_path}{$new_path};
        my ($result2, $_new_file, $new_content)
          = $translation->_apply_copy_option($new_file, $new_option, $new_path, $new_path);
        return if not $result2;

        $self->debug("old content is empty") unless $old_content;
        $self->debug("new content is empty") unless $new_content;

        if ($old_content and $new_content) {
          if (my $diff = Text::Diff::diff(\$old_content, \$new_content)) {
            print $out "--- $old_file\n+++ $new_file\n$diff\n\n"
          }
        }
      }
    }
  } else { # default
    # original vs translation
    $wanted = sub {
      if (-f $File::Find::name) {
        my $old_file = $File::Find::name;
        my $new_file = $old_file;
        my ($result, $_new_file, $old_content)
          = $translation->_apply_copy_option($old_file, $old_option, $old_path, $new_path);
        return if not $result or not $old_content;
        $_new_file =~s{^$old_path}{$new_path};
        my $new_content = encoding_slurp("$_new_file", $enc) or return;
        if (my $diff = Text::Diff::diff(\$old_content, \$new_content)) {
          print $out "--- $old_file\n+++ $_new_file\n$diff\n\n";
        }
      }
    }
  }
  File::Find::find({no_chdir => 1, wanted => $wanted}, $old_path,);
}

sub usage_desc {
  return 'tran diff [-o/-t] RESOURCE TARGET [FILES ...]';
}

sub validate_args {
  my ($self, $opt, $args) = @_;
  $self->usage_error("arguments are not enough.")  if @$args < 2;
}

sub description {
  return <<DESC;
show difference of target in repositories.
normaly, show difference between original and translation.
DESC
}

1;

=head1 NAME

Tran::Cmd::diff - difference of translation/original/original and translation

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
