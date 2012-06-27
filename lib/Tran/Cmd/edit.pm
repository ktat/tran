package Tran::Cmd::edit;

use warnings;
use strict;
use Tran::Cmd -command;
use Tran;
use Tran::Util -common, -debug, -string;
use File::Path qw/make_path/;
use IO::Prompt;

sub abstract {  'list directory contents'; }

sub opt_spec {
  return (
          ['resource|r=s', "resource. required." ],
         );
}

sub run {
  my ($self, $opt, $args) = @_;
  my ($target, $version, @rest) = @$args;
  if (defined $version and ($version =~m{/} or $version =~m{.pod$})) {
    ($target, @rest) = @$args;
    undef $version;
  }

  my $resource = camelize($opt->{resource});

  $opt->{translation} = $opt->{translation_repository};

  my $tran = $self->app->tran;
  my $r = $tran->resource($resource);
  my $repo = $tran->translation_repository($r->target_translation($target));
  my $path = $repo->path_of($target, $version || $repo->latest_version($target));
  my $rest_path = path_join @rest;
  $path = path_join $path, $1 if $rest_path =~m{^/?(.+)$};
  my $out;
  if (-f $path or -f ($path .= '.pod')) {
    exec( ($ENV{TRAN_EDITOR} || $ENV{EDITOR}), $path);
  } else {
    die "$path is not a file.\n";
  }
}

sub usage_desc {
  return 'tran cat -r RESOURCE TARGET [OPTION] [VERSION] path/to/anywhere';
}

sub validate_args {
  shift()->Tran::Cmd::_validate_args_resource(@_, 1);
}


1;

=head1 NAME

Tran::Cmd::edit

=head1 AUTHOR

Ktat, C<< <ktat at cpan.org> >>

=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2012 Ktat.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Tran
