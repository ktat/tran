package Tran::Cmd::init;

use warnings;
use strict;
use Tran::Util -base;
use Tran::Cmd -command;
use Tran::Config;
use IO::Prompt;


sub abstract { 'initialize config file'; }

sub run {
  my $self = shift;
  my $config_dir = $ENV{HOME} . '/.tran';
  my $config = "$config_dir/config.yml";

  my ($type, $original, $translation);

  if (-e $config) {
    $self->fatal("already exists.");
  }

  mkdir $config_dir unless -d $config_dir;

  my $c = Tran::Config->new($config);
  1 until $type = prompt("repository type:");
  $type = $type->{value} || 'file';

  unless (Tran::VCS->is_supported($type)) {
    $self->fatal("not supported type: $type");
  }

  $c->set_repository_type($type);

  1 until $original = prompt("original repository location:");
  chomp($original);
  $original = $original->{value} || "$config_dir/original";

  1 until $translation = prompt("tranlsation repository location:");
  chomp($translation);
  $translation = $translation->{value} || "$config_dir/translation";

  $c->set_original_repository($original);
  $c->set_translation_repository($translation);

  $c->save ? $self->info("file is created.") : $self->fatal("faile to craete file.");
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
