package Tran::Cmd;

use warnings;
use strict;
use App::Cmd::Setup -app;
use Tran;
use IO::Prompt ();

sub new {
  my ($self, $tran) = @_;
  die "Tran object is needed" unless $tran;
  my $obj = $self->SUPER::new;
  $obj->{tran} = $tran;
  $obj->{log} = $tran->log;
  $obj->{plugin_search_path} = __PACKAGE__;
  return $obj;
}

sub log {
  my $self = shift;
  $self->{log};
}

sub tran {
  my $self = shift;
  $self->{tran};
}

sub prompt {
  my ($self, $message) = @_;
  $message ||= '';
  chomp(my $answer = IO::Prompt::prompt($message . '(Y/n)'));
  return lc($answer) eq 'y' || 0;
}

sub _validate_args_resource {
  my ($self, $opt, $args, $n) = @_;
  unless ($opt->{resource} ||= $self->app->tran->config->default_resource) {
    $self->usage_error("-r option is required or you can set default_resource in you ~/.tran/config.yml");
  }
  $self->usage_error("arguments are not enough.")  if @$args < $n;
}

1;

=head1 NAME

Tran::Cmd

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
