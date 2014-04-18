package Tran::Cmd::ls;

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
          ['translation|t', "list translation directory contents" ],
          ['version|s', "specify version" ],
         );
}

sub run {
  my ($self, $opt, $args) = @_;
  my ($target, @rest) = @$args;
  my $version = $opt->{version};

  my $resource = camelize($opt->{resource});

  my $tran = $self->app->tran;
  my $r = $tran->resource($resource);
  if (not $r->has_target($target)) {
    $r = $r->find_target_resource($target);
  }
  my $path;
  my $repo = $opt->{translation} ? $r->find_translation_repository($target) : $r->original_repository;

  if (defined $target and $target) {
    $path = $repo->path_of($target, $version || $repo->latest_version($target));
    my $rest_path = path_join @rest;
    $path = path_join $path, $1 if $rest_path =~m{^/?(.+)$};
  }
  if (-f $path) {
    print "[ $path ]\n";
    print $path, "\n";
  } elsif (opendir my $d, $path) {
    print "[ $path ]\n";
    print join "\n", map "$_", (grep !/^\.\.?$/, readdir $d), "";
    closedir $d;
  } else {
    die "cannot open $path: $!\n"
  }
}

sub usage_desc {
  return 'tran ls [OPTIONS] TARGET path/to/anywhere';
}

sub validate_args {
  my $self = shift;
  my ($opt, $args) = @_;
  $self->Tran::Cmd::_validate_args_resource(@_, 1);
}


1;

=head1 NAME

Tran::Cmd::ls

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
