package Tran::Repository::Translation;

use warnings;
use strict;
use Tran::Util -debug, -common, -file, -list;
use File::Path ('make_path');
use Text::Diff3;

use base qw/Tran::Repository/;

sub new {
  my ($class, %self) = @_;
  my $o = $class->SUPER::new(%self);
  if ($class =~s{::Repository::Translation::}{::VCS::}) {
    if (Class::Inspector->loaded($class)) {
      $o->debug("repository has vcs: $class");
      $o->{vcs} = $class->new(%{$self{config}->{vcs}});
      $o->{vcs}->{log} = $self{log};
    }
  }
  return $o;
}

sub encoding {
  my $self = shift;
  $self->{encoding};
}

sub vcs {
  my $self = shift;
  $self->{vcs};
}

sub has_target {
  my ($self, $target) = @_;
  my $target_path = $self->target_path($target);
  if (opendir my $dir, $self->directory) {
    return any {/^$target_path\-/} readdir $dir ? 1 : 0;
  } else {
    $self->fatal(sprintf "cannot open directory %s", $self->directory);
  }
}

sub original {
  my $self = shift;
  $self->{config}->{directory};
}

sub original_repository {
  my $self = shift;
  $self->{original};
}

sub path_format { return "%n-%v" }

sub merge {
  my ($self, $target, $prev_version, $version, $option) = @_;
  my $target_path = $self->target_path($target);
  $option ||= {};

  my $original_repository   = $self->original_repository;

  my @newer_original_files = $original_repository->files($target_path, $version);
  my @translated_files     = $self->files($target_path, $prev_version);

  my $omit_path = $option->{omit_path} || '';

  if ($omit_path) {
    @newer_original_files = grep {s{^/?$omit_path}{}} @newer_original_files;
  }

  my %target;
  @target{@translated_files} = ();
  my %diff;

  my $translation_dir = $self->directory;

  my $translation_path     = $self->path_of($target_path, $prev_version);
  my $new_translation_path = $self->path_of($target_path, $version);
  my $newer_original_path  = $original_repository->path_of($target_path, $version);
  my $older_original_path  = $original_repository->path_of($target_path, $prev_version);

  if ($omit_path) {
    $newer_original_path .= "/$omit_path";
    $older_original_path .= "/$omit_path";
  }

  my $v = quotemeta($version->{original});

  my $merge_method = $self->merge_method;
  $merge_method ||= 'cmpmerge';


  foreach my $file (grep $_, @newer_original_files) {
    die $version unless $v;
    if (exists $target{$file}           and
        -f "$newer_original_path/$file" and
        -f "$older_original_path/$file" and
        -f "$translation_path/$file"
       ) {
      my $merged = $self->$merge_method("$newer_original_path/$file",
                            "$older_original_path/$file",
                            "$translation_path/$file");
      $self->_write_file_auto_path("$new_translation_path/$file", $merged);
    } elsif (-f "$newer_original_path/$file") {
      $self->_copy_file_auto_path($file, $newer_original_path, $new_translation_path);
    }
  }
  return \%diff;
}

sub _write_file_auto_path {
  my ($self, $file, $content) = @_;
  my $dir = $file;
  if ($dir =~s{([^/]+)$}{}) {
    make_path($dir);
  }
  write_file($file, $content);
}

sub copy_option { {} };

sub copy_from_original {
  my ($self, $target, $version) = @_;
  my $option = $self->copy_option || {};
  my $target_path = $self->target_path($target);
  my $original_repository = $self->original_repository;
  my $original_path       = $original_repository->path_of($target_path, $version);
  my $translation_path    = $self->path_of($target_path, $version);
  my @original_files      = $original_repository->files($target_path, $version);

  foreach my $name (qw/omit_path target_path ignore_path/) {
    $option->{$name} = [$option->{$name} || ()] unless ref $option->{$name};
  }
  foreach my $f (@original_files) {
    next if not -f "$original_path/$f";
    $self->_copy_file_auto_path($f, $original_path, $translation_path, $option);
  }
}

sub _copy_file_auto_path {
  my ($self, $file, $original, $translation, $option) = @_;
  my $to_file = $file;
  my $contents = '';
  my $is_target = 0;

  Carp::croak("file is required") unless $file;
  foreach my $target (@{$option->{target_path}}) {
    if ($file =~ m{^/?$target/}) {
      $is_target = 1;
      last;
    }
  }
  foreach my $ignore (@{$option->{ignore_path}}) {
    if ($file =~ m{^/?$ignore/}) {
      return;
    }
  }
  return if @{$option->{target_path}} and not $is_target;

  foreach my $omit (@{$option->{omit_path}}) {
    if ($to_file =~ s{^/?$omit/}{}) {
      last;
    }
  }

  if ($option->{exchange_path}) {
    my $_translation = $option->{exchange_path}->($self, $file, $original, $translation);
    $translation = $_translation if $_translation;
  }

  if ($option->{name_filter}) {
    $to_file = $option->{name_filter}->($self,$to_file);
  }

  if ($option->{contents_filter}) {
    $contents = slurp("$original/$file");
    $contents = $option->{contents_filter}->($self, $file, $contents);
  }

  my $dir = $to_file;
  if ($dir =~s{([^/]+)$}{}) {
    my $to_file = $1;
    if (!-e  "$translation/$dir") {
      $self->debug("create directory: $translation/$dir");
      make_path("$translation/$dir") or die "$translation/$dir";
    } elsif (! -d "$translation/$dir") {
      $self->fatal("$translation/$dir exists, but not directory.");
    }
    if (! -e "$translation/$dir/$to_file") {
      if (-d "$original/$file") {
        # make_path("$translation/$dir/$to_file") or die "$translation/$dir/$to_file";
      } else {
        if ($contents) {
          $self->debug("copy file: $original/$file to $translation/$dir/$to_file (with modification)");
          $self->_write_file_auto_path("$translation/$dir/$to_file", $contents)
            or $self->fatal("cannot copy write $translation/$to_file: $!");
        } else {
          $self->debug("copy file: $original/$file to $translation/$dir/$to_file");
          copy "$original/$file", "$translation/$dir/$to_file"
            or $self->fatal("cannot copy file $file: $!");
        }
      }
    }
  }
}

sub cmpmerge {
  my ($self, $newer_file, $older_file, $translation_file) = @_;
  my $f = Text::Diff3::Factory->new;

  my $translation = $f->create_text([grep chomp, slurp($translation_file)]);
  my $old = $f->create_text([grep chomp, slurp($older_file)]);
  my $new = $f->create_text([grep chomp, slurp($newer_file)]);

  my $p = $f->create_diff3;
  my $d3 = $p->diff3( $translation, $old, $new );

  my $i2 = 1; # line number start from 1 for this factory.
  my $source;
  $d3->each
    (sub {
       my ($r) = @_;
       $source .=  $old->as_string_range($i2 .. $r->lo2 - 1);
       if ( $r->type eq "A" ) { # conflict (all are different)
         $source .= "<<<<<<< $translation_file\n";
         $source .= $translation->as_string_range($r->range0);
         $source .= "||||||| $older_file\n";
         $source .= $old->as_string_at( $_ ) for $r->range2;
         $source .= "=======\n";
         $source .= $new->as_string_range($r->range1);
         $source .= ">>>>>>> $newer_file\n";
       } elsif ( $r->type eq "0" ) { # translation is different, older == newer version
         $source .= $translation->as_string_range($r->range0);
       } elsif ( $r->type eq "2" ) { # older is different. translation == newer version
         # it should be ignore? just use newer version
         $source .=  $new->as_string_range($r->range1);;
       } elsif ( $r->type eq "1" ) { # newer is different. translation == older version
         $source .= ">>>>>>> $newer_file\n";
         $source .= $new->as_string_range($r->range1);
         $source .= "<<<<<<<\n";
       }
       $i2 = $r->hi2 + 1;
     } );
  $source .= $old->as_string_range($i2 .. $old->last_index);
  return $source;
}

sub cmpmerge_least {
  my ($self, $newer_file, $older_file, $translation_file) = @_;
  my $f = Text::Diff3::Factory->new;

  my $translation = $f->create_text([grep chomp, slurp($translation_file)]);
  my $old = $f->create_text([grep chomp, slurp($older_file)]);
  my $new = $f->create_text([grep chomp, slurp($newer_file)]);

  my $p = $f->create_diff3;
  my $d3 = $p->diff3( $translation, $old, $new );

  my $i2 = 1; # line number start from 1 for this factory.
  my $source;
  $d3->each
    (sub {
       my ($r) = @_;
       $source .=  $old->as_string_range($i2 .. $r->lo2 - 1);
       if ( $r->type eq "A" ) { # conflict (all are different)
         $source .= "<<<<<<< $translation_file\n";
         $source .= $translation->as_string_range($r->range0);
         $source .= "=======\n";
         $source .= $new->as_string_range($r->range1);
         $source .= ">>>>>>> $newer_file\n";
       } elsif ( $r->type eq "0" ) { # translation is different, older == newer version
         $source .= $translation->as_string_range($r->range0);
       } elsif ( $r->type eq "2" ) { # older is different. translation == newer version
         # something wrong?
         $source .= $new->as_string_range($r->range1);;
       } elsif ( $r->type eq "1" ) { # newer is different. translation == older version
         $source .= $new->as_string_range($r->range1);
       }
       $i2 = $r->hi2 + 1;
     } );
  $source .=  $old->as_string_range($i2 .. $old->last_index);
  return $source;
}

sub notify {
  my ($self) = @_;
  return $self->{config}{notify};
}

sub update_version_info { }

sub merge_method {
  my $self = shift;
  $self->{config}{merge_method};
}

sub _config {
  return {
          merge_method => 'cmpmerge',
         };
}

=head1 NAME

Tran::Repository::Translation

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
