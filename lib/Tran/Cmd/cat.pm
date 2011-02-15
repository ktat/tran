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
          ['translation|t', "show translation file " ],
          ['number|n', "show content with line number" ],
         );
}

sub run {
  my ($self, $opt, $args) = @_;
  my ($target, $version, @rest) = @$args;
  my $resource = camelize($opt->{resource});

  my $tran = $self->app->tran;
  my $r = $tran->resource($resource);
  my $repo = $opt->{translation} ? $tran->translation($r->target_translation($target)) : $r->original_repository;
  my $path = $repo->path_of($target, $version);
  my $rest_path = join "/", @rest;
  $path .= "/" . $1 if $rest_path =~m{^/?(.+)$};
  my $out;
  if (-f $path) {
    if ($ENV{TRAN_PAGER}) {
      open $out, "|-", $ENV{TRAN_PAGER} or $self->fatal("cannot open '$ENV{TRAN_PAGER}' with mode '|-'");
    } else {
      $out = *STDOUT;
    }
    local @SIG{qw/INT KILL TERM QUIT/} = (sub {close $out; exit;}) x 4;
    my $c = slurp($path);
    my $i = 1;
    $c =~ s{^}{sprintf "%4d ", $i++}meg if $opt->{number};
    print $out $c;
  } else {
    die "$path is not a file.\n";
  }

}

sub usage_desc {
  return 'tran get -r RESOURCE TARGET [VERSION] path/to/anywhere';
}

sub validate_args {
  shift()->Tran::Cmd::_validate_args_resource(@_, 1);
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
