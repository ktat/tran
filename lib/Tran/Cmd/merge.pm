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
  if (not $tran->translation_repository->{$translation}) {
    die "You may pass wrong trnaslation repository name: $translation\n  "
      . "choose one of them: " . join(', ', keys %{$tran->translation_repository}) . "\n";
  }
  my $tr_path  = $tran->translation_repository->{$translation}->directory;

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

  my $class = $tran->translation_repository->{$translation};
  my $copy_option = $class->copy_option || {};
  my $merge_method = $class->merge_method;
  my $merged = $class->$merge_method
    ($newer, $older, $translated, $copy_option->{contents_filter});

  unless($new_file) {
    print $merged;
  } else {
    write_file($new_file, $merged);
    $self->info("merged result is written: $new_file");
  }
}

sub usage_desc {
  return 'tran merge TRANSLATION_REPOSITORY OLDER_ORIGINAL_FILE NEWER_ORIGINAL_FILE OLDER_TRANSLATION_FILE [NEWER_TRANSLATION_FILE]' . "\n"
       . 'ARGUMENTS:' . "\n"
       . 'TRANSLATION_REPOSITORY ... name of translation repository (for example, jprp-modules)' . "\n"
       . 'OLDER_ORIGINAL_FILE ...... relative(from original repository root) or absorute path of an old original file' . "\n"
       . 'NEWER_ORIGINAL_FILE ...... relative(from original repository root) or absorute path of newer original file' . "\n"
       . 'OLDER_TRANSLATION_FILE ... relative(from translation repository root) or absorute path of older translation file' . "\n"
       . 'NEWER_TRANSLATION_FILE ... relative(from translation repository root) or absorute path of newer translation file. If not specified, print to STDOUT' . "\n"

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
