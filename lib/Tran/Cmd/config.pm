package Tran::Cmd::config;

use warnings;
use strict;
use Tran::Util -common, -file;
use Tran::Cmd -command;
use YAML::XS qw/Dump/;
sub abstract {  'show config file'; }

sub run {
  my ($self, $opt, $args) = @_;
  if (defined $args) {
    my %config;
    @config{@$args} = @{$self->app->tran->config->{config}}{@$args};
    print Dump(\%config);
  } else {
    print slurp $ENV{HOME} . '/.tran/config.yml';
  }
}

1;

=head1 NAME

Tran::Cmd::Config

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
