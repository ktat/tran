package Tran::Repository::Translation;

use warnings;
use strict;
use Tran::Util -debug, -common, -file, -list;
use File::Path ('make_path');
use Text::Diff3;
use Text::Diff3::Factory;

use base qw/Tran::Repository/;

sub new {
  my ($class, %self) = @_;
  my $o = $class->SUPER::new(%self);
  if ($class =~s{(::Repository::Translation::[^:+])}{$1::VCS}) {
    if (Class::Inspector->loaded($class)) {
      $o->debug("repository has vcs: $class");
      $o->{vcs} = $class->new(%{$self{config}->{vcs}});
      $o->{vcs}->{log} = $self{log};
    }
  }
  return $o;
}

sub tran {
  my $self = shift;
  $self->{tran};
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

# sub original {
#   my $self = shift;
#   $self->{config}->{directory};
# }

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

  my @newer_original_files = $original_repository->files($target, $version);
  my @translated_files     = $self->files($target_path, $prev_version);

  my %target;
  @target{@translated_files} = ();
  my %diff;

  my $translation_dir = $self->directory;

  my $translation_path     = $self->path_of($target, $prev_version);
  my $new_translation_path = $self->path_of($target, $version);
  my $newer_original_path  = $original_repository->path_of($target, $version);
  my $older_original_path  = $original_repository->path_of($target, $prev_version);

  my $v = quotemeta($version->{original});
  die $version unless $v;

  my $copy_option = $self->copy_option;
  foreach my $name (qw/omit_path target_path ignore_path/) {
    $copy_option->{$name} = [$copy_option->{$name} || ()] unless ref $copy_option->{$name};
  }

  my $merge_method = $option->{merge_method} ? $option->{merge_method} : $self->merge_method;
  my $name_filter = $copy_option->{name_filter};

 FILE:
  foreach my $file (grep $_, @newer_original_files) {
    $self->debug("merge target file: ". $file);

    my $_file = $file;
    my $_translation_path     = $translation_path;
    my $_new_translation_path = $new_translation_path;
    my $_newer_original_path  = $newer_original_path;
    my $_older_original_path  = $older_original_path;

    my $is_target = 0;
    foreach my $target (@{$copy_option->{target_path}}) {
      if ($_file =~ m{^/?$target/} or $_file =~ m{^/?$target$}) {
        $is_target = 1;
        last;
      }
    }

    foreach my $ignore (@{$copy_option->{ignore_path}}) {
      if ($_file =~ m{^/?$ignore/}) {
        next FILE;
      }
    }
    next FILE if @{$copy_option->{target_path}} and not $is_target;

    foreach my $omit (@{$copy_option->{omit_path}}) {
      if ($_file =~ s{^/?$omit/}{/}) {
        $_newer_original_path .= "/$omit";
        $_older_original_path .= "/$omit";
        last
      }
    }

    if ($copy_option->{exchange_path}) {
      my $__translation_path = $copy_option->{exchange_path}->($self, $_file, $_newer_original_path, $_translation_path);
      $_translation_path = $__translation_path if $__translation_path;
      my $__new_translation_path = $copy_option->{exchange_path}->($self, $_file, $_newer_original_path, $_new_translation_path);
      $_new_translation_path = $__new_translation_path if $__new_translation_path;
    }

    my $nf = "$_newer_original_path/$_file";
    my $of = "$_older_original_path/$_file";
    my $translation_file = $_file;
    if ($name_filter) {
      $translation_file = $name_filter->($self, $_file);
    }
    my $tf = "$_translation_path/$translation_file";

    if (exists $target{$translation_file} and -f $nf and -f $of and -f $tf) {
      $self->debug("merge target: $translation_file");
      my $merged = $self->$merge_method($nf, $of, $tf, $copy_option->{contents_filter});
      my $ntf = "$_new_translation_path/$translation_file";
      $ntf = $name_filter->($self, $ntf) if $name_filter;
      $self->_write_file_auto_path($ntf, $merged);
    } elsif (-f $nf) {
      $self->debug("copy target: $file");
      $self->_copy_file_auto_path($file, $newer_original_path, $new_translation_path, $copy_option);
    }
  }
  return \%diff;
}

sub _apply_copy_option {
  my ($self, $file, $copy_option, $old_path, $new_path) = @_;
  my $_file = $file;
  $_file =~ s{^$old_path/?}{};

  foreach my $name (qw/omit_path target_path ignore_path/) {
    $copy_option->{$name} = [$copy_option->{$name} || ()] unless ref $copy_option->{$name};
  }
  my $is_target = 0;
  foreach my $target (@{$copy_option->{target_path}}) {
    if ($_file =~ m{^/?$target/}) {
      $is_target = 1;
      last;
    }
  }
  foreach my $ignore (@{$copy_option->{ignore_path}}) {
    if ($_file =~ m{^/?$ignore/}) {
      return 0;
    }
  }

  foreach my $ignore (@{$copy_option->{ignore_path_any_depth}}) {
    if ($_file =~ m{^/?$ignore/} or $_file =~ m{/$ignore/}) {
      return 0;
    }
  }

  return 0 if @{$copy_option->{target_path}} and not $is_target;

  foreach my $omit (@{$copy_option->{omit_path}}) {
    if ($_file =~ s{^/?$omit/}{/}) {
      last
    }
  }
  if ($copy_option->{name_filter}) {
    $_file = $copy_option->{name_filter}->($self, $_file);
  }

  my $content = encoding_slurp($file, $self->encoding);
  if ($copy_option->{contents_filter}) {
    $content = $copy_option->{contents_filter}->($self, $file, $content);
  }
  return (1, "$new_path/$_file", $content);
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

  # todo: this setting shoud be in other place.
  push @{$option->{ignore_path_any_depth} ||= []}, '.git';

  my $target_path = $self->target_path($target);
  my $original_repository = $self->original_repository;
  my $original_path       = $original_repository->path_of($target, $version);
  my $translation_path    = $self->path_of($target, $version);
  my @original_files      = $original_repository->files($target, $version);

  foreach my $name (qw/omit_path target_path ignore_path ignore_path_any_depth/) {
    $option->{$name} = [$option->{$name} || ()] unless ref $option->{$name};
  }
  foreach my $f (@original_files) {
    next if not -f "$original_path/$f";
    $self->_copy_file_auto_path($f, $original_path, $translation_path, $option);
  }
}

sub _copy_file_auto_path {
  my ($self, $file, $original, $translation, $option) = @_;
  Carp::croak("file is required") unless $file;

  my $to_file = $file;
  my $contents = '';
  my $is_target = 0;

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

  foreach my $ignore (@{$option->{ignore_path_any_depth}}) {
    if ($file =~ m{^/?$ignore/} or $file =~ m{/$ignore/}) {
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
        } elsif (! $option->{contents_filter}) {
          $self->debug("copy file: $original/$file to $translation/$dir/$to_file");
          copy "$original/$file", "$translation/$dir/$to_file"
            or $self->fatal("cannot copy file $original/$file => $translation/$dir/$to_file: $!");
        } else {
          $self->debug("ignore file: $original/$file is empty.");
        }
      }
    }
  }
}

sub cmpmerge {
  my ($self, $newer_file, $older_file, $translation_file, $contents_filter) = @_;
  my $f = Text::Diff3::Factory->new;

  my $translation = $f->create_text([grep chomp, slurp($translation_file)]);
  my ($old, $new);
  if (ref $contents_filter eq 'CODE') {
    $old = $f->create_text([split /\n/, $contents_filter->($self, $older_file, scalar slurp($older_file))]);
    $new = $f->create_text([split /\n/, $contents_filter->($self, $newer_file, scalar slurp($newer_file))]);
  } else {
    $old = $f->create_text([grep chomp, slurp($older_file)]);
    $new = $f->create_text([grep chomp, slurp($newer_file)]);
  }

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
         $source .= "======= $newer_file\n";
         $source .= $new->as_string_range($r->range1);
         $source .= ">>>>>>> END\n";
       } elsif ( $r->type eq "0" ) { # translation is different, older == newer version
         $source .= $translation->as_string_range($r->range0);
       } elsif ( $r->type eq "2" ) { # older is different. translation == newer version
         # it should be ignore? just use newer version
         $source .=  $new->as_string_range($r->range1);
       } elsif ( $r->type eq "1" ) { # newer is different. translation == older version
         $source .= "<<<<<<< $newer_file\n";
         $source .= $new->as_string_range($r->range1);
         $source .= ">>>>>>> END\n";
       }
       $i2 = $r->hi2 + 1;
     } );
  $source .= $old->as_string_range($i2 .. $old->last_index);
  return $source;
}

sub cmpmerge_least {
  my ($self, $newer_file, $older_file, $translation_file, $contents_filter) = @_;
  my $f = Text::Diff3::Factory->new;

  my $translation = $f->create_text([grep chomp, slurp($translation_file)]);
  my ($old, $new);
  if (ref $contents_filter eq 'CODE') {
    $old = $f->create_text([split /\n/, $contents_filter->($self, $older_file, scalar slurp($older_file))]);
    $new = $f->create_text([split /\n/, $contents_filter->($self, $newer_file, scalar slurp($newer_file))]);
  } else {
    $old = $f->create_text([grep chomp, slurp($older_file)]);
    $new = $f->create_text([grep chomp, slurp($newer_file)]);
  }
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
         $source .= "======= $newer_file\n";
         $source .= $new->as_string_range($r->range1);
         $source .= ">>>>>>> END\n";
       } elsif ( $r->type eq "0" ) { # translation is different, older == newer version
         $source .= $translation->as_string_range($r->range0);
       } elsif ( $r->type eq "2" ) { # older is different. translation == newer version
         # something wrong?
         $source .= $new->as_string_range($r->range1);
       } elsif ( $r->type eq "1" ) { # newer is different. translation == older version
         $source .= "<<<<<<< $newer_file\n";
         $source .= $new->as_string_range($r->range1);
         $source .= ">>>>>>> END\n";
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
  $self->{config}{merge_method} || $self->{merge_method} || 'cmpmerge_least';
}

sub _config {
  return {
          # merge_method => 'cmpmerge_least',
         };
}

=head1 NAME

Tran::Repository::Translation

=head2 METHODS

=head2 new

constructor.

=head2 tran

 $t->tran;

return Tran object.

=head2 encoding

 $t->encoding;

return encoding setting.

=head2 C<vcs>

 $t->vcs;

return Version control object if loaded.

=head2 has_target

 $t->has_target($target_name);

If translation repository has $target_name translation,
return true.

=head2 original_repository

 $t->original_repository;

return original repository of translation.

=head2 path_format

 $self->path_format; # like '%n-%v'

Path format in translation repository.
'%n' is target name, %v is version number.

If it returns undef, any path is added to translation directory.

=head2 path_of

 $repo->path_of($target, $version);

It returns target directory in the repository.
This method's behavior is depend on C<path_format>.

=over 4

=item path_format returns undef

returns repository's directory.

=item path_format returns empty string

if target name is 'AAA::BBB', it returns:

 /path/to/repository/directory/AAA-BBB

=item path_format returns string

If string has %n and/or %v, it/they is/are replaced.

 %n ... target name
 %v ... version

So, if string is '%n-%v' and target name is 'AAA::BBB' and version is "0.01",
it returns:

 /path/to/repository/directory/AAA-BBB-0.01

=back

=head2 merge

 $t->merge($target, $prev_version, $version, $copy_option);

merge difference between original old version and original newer version into old translation file.

=head2 copy_option

 $t->copy_option;

it is defined in subclass.
like the following(in Translation::JprpModules):

 sub copy_option {
   return {
           ignore_path     => ['t', 'inc'],
           # see Tran::Util
           contents_filter => \&pm2pod,
           name_filter     => \&pm2pod_name,
          };
 }

=head2 copy_from_original

 $t->copy_from_original($target, $version);

copy target's original files to translation path.

=head2 C<cmpmerge>

  $t->cmpmerge($newer_file, $older_file, $translation_file, $contents_filter);

=head2 C<cmpmerge_least>

  $t->cmpmerge_least($newer_file, $older_file, $translation_file, $contents_filter);

=head2 notify

 $t->notify;

return notify setting for translation.

=head2 update_version_info

 $t->update_version_info;

update version information in the translation repository.
It is implemented in subclass.

=head2 merge_method

 $t->merge_method;

return merge_method setting.
If not set, 'cmpmerge_least' is used.

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
