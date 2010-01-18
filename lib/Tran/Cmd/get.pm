package Tran::Cmd::get;

use warnings;
use strict;
use Tran::Cmd -command;
use Tran;
use Tran::Util -common, -debug, -string;
use File::Path qw/make_path/;
use IO::Prompt;

sub abstract {  'get original files from resource'; }

sub run {
  my ($self, $opt, $args) = @_;
  my ($resource, $target, $version, @rest) = @$args;

  $resource = camelize($resource);

  my $tran = $self->app->tran;
  my $r = $tran->resource($resource);
  my $_target = '';
  my @result = $r->get($target, $version, @rest);
  if (@result == 2) {
    if (defined $version and $version) {
      $self->info("You have $target($result[1]) in original repository");
    } else {
      $self->info("You have the latest version($result[1]) of $target in original repository");
    }
  } else {
    $self->info("Got $target " . ($version || '') );
  }
}

sub usage_desc {
  return 'tran get RESOURCE TARGET [VERSION/URL]';
}

sub validate_args {
  my ($self, $opt, $args) = @_;
  $self->usage_error("arguments are not enough.")  if @$args < 2;
}


1;

=head1 NAME

Tran::Cmd::get

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
