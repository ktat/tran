package Tran::Repository::Translation;

use warnings;
use strict;
use Tran::Util -debug, -base, -file;
use File::Path ('make_path');
use Text::Diff3;

use base qw/Tran::Repository/;

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
  my ($self, $target_path, $prev_version, $version, $option) = @_;
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

sub copy_from_original {
  my ($self, $target_path, $version, $option) = @_;
  $option ||= {};
  my $original_repository = $self->original_repository;
  my $original_path       = $original_repository->path_of($target_path, $version);
  my $translation_path    = $self->path_of($target_path, $version);
  my @original_files      = $original_repository->files($target_path, $version);
  my $omit_path = $option->{omit_path} || '';
  if ($omit_path) {
    @original_files = grep {s{^/?$omit_path}{}} @original_files;
  }
  $self->_copy_file_auto_path($_, "$original_path/$omit_path", $translation_path) for grep $_, @original_files;
}

sub _write_file_auto_path {
  my ($self, $file, $content) = @_;
  my $dir = $file;
  if ($dir =~s{([^/]+)$}{}) {
    make_path($dir);
  }
  write_file($file, $content);
}

sub _copy_file_auto_path {
  my ($self, $file, $original, $translation) = @_;
  Carp::croak("file is required") unless $file;
  my $dir = $file;
  if ($dir =~s{([^/]+)$}{}) {
    my $file = $1;
    if (!-e  "$translation/$dir") {
      $self->debug("create directory: $translation/$dir");
      make_path("$translation/$dir") or die "$translation/$dir";
    } elsif (! -d "$translation/$dir") {
      $self->fatal("$translation/$dir exists, but not directory.");
    }
    if (! -e "$translation/$dir/$file") {
      if (-d "$original/$dir/$file") {
        make_path("$translation/$dir/$file") or die "$translation/$dir/$file";
      } else {
        $self->debug("copy file: $file from $original to $translation");
        copy "$original/$dir/$file", "$translation/$dir/$file"
          or $self->fatal("cannot copy file");
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

sub merge_method { }

1;

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
