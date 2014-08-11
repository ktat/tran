package Tran::Cmd::get;

use warnings;
use strict;
use Tran::Cmd -command;
use Tran;
use Tran::Util -common, -debug, -string;
use File::Path qw/make_path/;
use IO::Prompt;

sub abstract {  'get original files from resource'; }

sub opt_spec {
  return (
          ['resource|r=s', "resource. required." ],
         );
}

sub run {
  my ($self, $opt, $args) = @_;
  my ($target, $version, @rest) = @$args;
  my $resource = camelize($opt->{resource});

  my $tran = $self->app->tran;
  my $r = $tran->resource($resource);
  if (not $r->has_target($target)) {
    my $r_test = $r->find_target_resource($target);
    if ($r_test) {
      my $resource_name = ref $r_test;
      $resource_name =~ s{Tran::Resource::}{};
      $resource_name = decamelize($resource_name);
      $self->app->prompt("other resource(not " . lc($resource) . ") is found: use resouce '" . $resource_name . "' ?")
	and $r = $r_test;
    }
  }
  my ($result, @result) = $r->get($target, $version, @rest);

  my $optional_path;
  if (ref $result[-1] eq 'ARRAY') {
    ($target, $optional_path) = @{$result[-1]};
  }

  if ($result == 0) {
    if (defined $version and $version) {
      $self->info("You have $target($result[1]) in original repository");
    } else {
      $self->info("You have the latest version($result[1]) of $target in original repository");
    }
  } else {
    $self->info("Got $target " . ($version || '') );
  }
  return (\@result, [$target, $optional_path]);
}

sub usage_desc {
  return 'tran get -r RESOURCE TARGET [VERSION/URL]';
}

sub validate_args {
  shift()->Tran::Cmd::_validate_args_resource(@_, 1);
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
