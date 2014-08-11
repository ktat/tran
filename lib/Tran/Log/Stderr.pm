package Tran::Log::Stderr;

use strict;
use warnings;

use base qw(Tran::Log);

sub _do_log {
  my ($self, $message) = @_;
  print STDERR $message, "\n";
}

sub _config { {} }

1;

=pod

=head1 NAME

Tran::Log::Stderr

=head1 SYNOPSYS

in config.yml:

 log:
   class: Stderr
   level: debug

=head1 COPYRIGHT & LICENSE

Copyright 2009 Ktat, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
