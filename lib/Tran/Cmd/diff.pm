package Tran::Cmd::diff;
use lib qw(../../);
use warnings;
use strict;
use Tran::Cmd -command;
use Tran;
use Tran::Util -common, -debug, -string;
use Text::Diff ();
use File::Find qw/find/;

sub abstract { 'show diffrence'; }

sub opt_spec {
  return (
          ['resource|r=s' , "resource. required if not set default_resource in config." ],
          ['translation|t', "show difference from translation repository" ],
          ['original|o'   , "show difference from original repository" ],
          ['trim'         , "remove whitespaces before and after" ],
          ['strip_class'  , "remove class in HTML tag" ],
          ['strip_tag'    , "remove HTML tag" ],
          ['version|v=s'  , "old_version / old_version:new_version" ],
         );
}

sub run {
  my ($self, $opt, $args) = @_;
  my ($target, @files) = @$args;
  my $resource_name = $opt->{resource};
  my ($version1, $version2) = $opt->{version} ? split(/:/, $opt->{version} || '', 2) : ();

  $| = 1;
  my $tran = $self->app->tran;
  my $resource = $tran->resource(camelize $resource_name);
  my ($old_path, $new_path);

  my $translation = $tran->translation_repository($tran->get_sticked_translation($target, $opt->{resource}) || $resource->target_translation($target));
  my $mode = 0;
  if ($opt->{translation}) {
    $mode = 1;
    $old_path = $translation->path_of($target, $version1 ||= $translation->prev_version($target));
    $new_path = $translation->path_of($target, $version2 ||= $translation->latest_version($target));
    $self->debug("diff between translation $version1 and translation $version2");
    $self->_diff($opt, $mode, $translation, $old_path, $new_path, {}, \@files);
  } elsif ($opt->{original}) {
    $mode = 2;
    my $copy_option = $translation->copy_option;
    my $original = $resource->original_repository;
    $old_path = $original->path_of($target, $version1 ||= $original->prev_version($target));
    $new_path = $original->path_of($target, $version2 ||= $original->latest_version($target));
    $self->debug("diff between original $version1 and original $version2");
    $self->_diff($opt, $mode, $translation, $old_path, $new_path, $copy_option, \@files);
  } else {
    my $original = $resource->original_repository;
    my $copy_option = $translation->copy_option;
    $old_path = $original->path_of($target   , $version1 ||= $original->latest_version($target));
    $new_path = $translation->path_of($target, $version2 ||= $translation->latest_version($target));
    $self->debug("diff between original $version1 and translation $version2");
    $self->_diff($opt, $mode, $translation, $old_path, $new_path, $copy_option, \@files);
  }
}

sub _diff {
  my ($self, $diff_option, $mode, $translation, $old_path, $new_path, $copy_option, $files) = @_;

  my $files_match;
  if (@$files) {
    $files_match = join '|', map {my $f = quotemeta($_); qr/$f/} @$files;
  }

  $self->fatal("missing old_path: $old_path") unless -d $old_path;
  $self->fatal("missing new_path: $new_path") unless -d $new_path;
  $self->debug("diff $old_path $new_path");

  my $wanted;
  my $enc = $translation->encoding;
  my $out;
  if ($ENV{TRAN_PAGER}) {
    open $out, "|-", $ENV{TRAN_PAGER} or $self->fatal("cannot open '$ENV{TRAN_PAGER}' with mode '|-'");
  } else {
    $out = *STDOUT;
  }
  local @SIG{qw/INT KILL TERM QUIT/} = (sub {close $out; exit 1;}) x 4;
  if ($mode == 1) { # -t
    # translation and translation
    $wanted = sub {
      if (-f $File::Find::name and $File::Find::name !~ m{/CVS/}) {
        my $old_file = $File::Find::name;
        my $old_content = encoding_slurp($old_file, $enc) or return;

        my $new_file = $old_file;
        $new_file =~s{^$old_path}{$new_path};
        if (-e $new_file) {
          if (defined $files_match and not $new_file =~ qr/$files_match/) {
            $self->info("$new_file is skipped");
            return;
          }
          my $new_content = encoding_slurp($new_file, $enc) or return;
          if (my $diff = Text::Diff::diff(\$old_content, \$new_content)) {
            print $out "--- $old_file\n+++ $new_file\n$diff\n\n";
          }
        } else {
          $self->info("$new_file is missing");
        }
      }
    }
  } elsif ($mode == 2) { # -o
    # original vs original
    $wanted = sub {
      if (-f $File::Find::name) {
        my $old_file = $File::Find::name;
        my ($result, $_old_file, $old_content)
          = $translation->_apply_copy_option($old_file, $copy_option, $old_path, $new_path);
        return if not $result;
        my $new_file = $old_file;
        $new_file =~s{^$old_path}{$new_path};
        my ($result2, $_new_file, $new_content)
          = $translation->_apply_copy_option($new_file, $copy_option, $new_path, $new_path);
        return if not $result2;
        if (defined $files_match and not $_new_file =~ qr/$files_match/) {
          $self->info("$_new_file is skipped");
          return;
        }

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
          = $translation->_apply_copy_option($old_file, $copy_option, $old_path, $new_path);
        return if not $result or not $old_content;

        $_new_file =~s{^$old_path}{$new_path};
        if (-e $_new_file) {
          if (defined $files_match and not $_new_file =~ qr/$files_match/) {
            $self->info("$_new_file is skipped");
            return;
          }

          my $new_content = encoding_slurp("$_new_file", $enc) or return;

	  if ($diff_option->{strip_class}) {
	    $new_content =~ s{(<.+?) class\s*=\s*(["']).+?\2(.*?>)}{$1$3}g;
	    $old_content =~ s{(<.+?) class\s*=\s*(["']).+?\2(.*?>)}{$1$3}g;
	  }
	  if ($diff_option->{strip_tag}) {
	    $new_content =~ s{<[^<]+?>}{}gs;
	    $old_content =~ s{<[^<]+?>}{}gs;
	  }
	  if ($diff_option->{trim}) {
	    $new_content =~ s{^[\s\t]+}{}gm;
	    $new_content =~ s{[\s\t]+$}{}gm;
	    $old_content =~ s{^[\s\t]+}{}gm;
	    $old_content =~ s{[\s\t]+$}{}gm;
	  }
          if (my $diff = Text::Diff::diff(\$old_content, \$new_content)) {
            print $out "--- $old_file\n+++ $_new_file\n$diff\n\n";
          }
        } else {
          $self->debug("$_new_file is missing.");
        }
      }
    }
  }
  File::Find::find({no_chdir => 1, wanted => $wanted}, $old_path,);
}

sub usage_desc {
  return 'tran diff [-o/-t] -r RESOURCE TARGET [FILES ...]';
}

sub validate_args {
  shift()->Tran::Cmd::_validate_args_resource(@_, 1);
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
