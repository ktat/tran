package Tran::Cmd::cat;

use warnings;
use strict;
use Tran::Cmd -command;
use Tran;
use Tran::Util -common, -debug, -string, -file;
use File::Path qw/make_path/;
use IO::Prompt;

sub abstract {  'show content of file'; }

sub opt_spec {
  return (
          ['resource|r=s', "resource. required." ],
          ['translation|t', "show translation file" ],
          ['number|n', "show content with line number" ],
          ['version|s', "specify version" ],
         );
}

sub run {
  my ($self, $opt, $args) = @_;
  my ($target, @rest) = @$args;
  my $version = $opt->{version};

  if (defined $version and ($version =~m{/} or $version =~m{.pod$} or $version =~m{.pm})) {
    ($target, @rest) = @$args;
    undef $version;
  }
  my $resource = camelize($opt->{resource});

  my $tran = $self->app->tran;
  my $r = $tran->resource($resource);
  if (not $r->has_target($target)) {
    $r = $r->find_target_resource($target);
  }
  my $repo = $opt->{translation} ? $r->find_translation_repository($target) : $r->original_repository;
  my $path = $repo->path_of($target, $version || $repo->latest_version($target));
  my $rest_path = path_join @rest;
  $path = path_join $path, $1 if $rest_path =~m{^/?(.+)$};

  my $out;
  if (-f $path) {
    if ($ENV{TRAN_PAGER}) {
      open $out, "|-", $ENV{TRAN_PAGER} or $self->fatal("cannot open '$ENV{TRAN_PAGER}' with mode '|-'");
    } else {
      $out = *STDOUT;
    }
    local @SIG{qw/INT KILL TERM QUIT/} = (sub {close $out; exit 1;}) x 4;
    my $c = slurp($path);
    my $i = 1;
    $c =~ s{^}{sprintf "%4d ", $i++}meg if $opt->{number};
    print $out $c;
  } else {
    die "$path is not a file.\n";
  }

}

sub usage_desc {
  return 'tran cat [OPTIONS] TARGET path/to/anywhere';
}

sub validate_args {
  shift()->Tran::Cmd::_validate_args_resource(@_, 2);
}


1;

=head1 NAME

Tran::Cmd::cat

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
