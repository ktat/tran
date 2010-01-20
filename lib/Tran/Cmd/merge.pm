package Tran::Cmd::merge;

use warnings;
use strict;
use Tran::Cmd -command;
use Tran;
use Tran::Util -common, -debug, -string, -file;
use File::Path qw/make_path/;
use IO::Prompt;

sub abstract {  'merge files manually'; }

sub run {
  my ($self, $opt, $args) = @_;
  my ($translation, $older, $newer, $translated, $new_file) = @$args;

  my $tran = $self->app->tran;

  my $org_path = $tran->original->directory;
  my $tr_path  = $tran->translation->{$translation}->directory;

  if (! $translation) {
    $self->fatal("translation repository name is missing!");
  }
  if (! -f $older and ! -f ($older = "$org_path/$older")) {
    $self->fatal("$older is missing!");
  }
  if (! -f $newer and ! -f ($newer = "$org_path/$newer")) {
    $self->fatal("$newer is missing!");
  }
  if (! -f $translated and ! -f ($translated = "$tr_path/$translated")) {
    $self->fatal("$translated is missing!");
  }
  if (defined $new_file and $new_file and 
      ! -f $new_file and ! -f ($new_file = "$tr_path/$new_file")) {
    $self->fatal("$new_file is missing!");
  }

  my $class = $tran->translation->{$translation};
  my $copy_option = $class->copy_option || {};
  my $merge_method = $class->merge_method || 'cmpmerge';
  my $merged = $class->$merge_method
    ($older, $newer, $translated, $copy_option->{contents_filter});

  unless($new_file) {
    print $merged;
  } else {
    write_file($new_file, $merged);
    $self->info("merged result is written: $new_file");
  }
}

sub usage_desc {
  return 'tran merge TRANSLATION_REPOSITORY OLDER_ORIGINAL_FILE NEWER_ORIGINAL_FILE OLDER_TRANSLATION_FILE';
}

sub validate_args {
  my ($self, $opt, $args) = @_;
  $self->usage_error("arguments are not enough.")  if @$args < 4;
}


1;

=head1 NAME

Tran::Cmd::merge

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
