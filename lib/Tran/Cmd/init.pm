package Tran::Cmd::init;

use warnings;
use strict;
use Tran::Util -base, -string;
use Tran::Cmd -command;
use Tran::Config;
use IO::Prompt;
use base qw/Data::Visitor/;

sub abstract { 'initialize config file'; }

sub run {
  my $self = shift;
  my $config_dir = $ENV{HOME} . '/.tran';
  my $config = "$config_dir/config.yml";

  $self->fatal("config file exists: $config") if -e $config;
  my $c = Tran::Config->new($config);

  my %config = (
                log => {
                        class => 'Stderr',
                        level => 'debug',
                       },
                notify => {},
               );
  foreach my $class (Tran->plugins) {
    if ($class->can('_config')) {
      my $_config = $class->_config;
      $self->{_config} = $_config;
      $config = $self->visit($_config);
      $class =~ s{^Tran::}{};
      my (@separate) = split /::/, $class;
      $separate[0] = lc($separate[0]);
      if ($separate[0] eq 'repository') {
        $separate[1] = lc($separate[1])
      }
      if (@separate == 3) {
        $separate[2] = lc(decamelize($separate[2]));
        $separate[2] =~ s{_}{-}g;
      }
      my $sub_config = $config{shift @separate} ||= {};
      $sub_config = $sub_config->{$_} ||= {} for @separate;
      %$sub_config = %$config;
    }
  }
  %{$c->{config}} = %config;
  $c->save ? $self->info("file is created.") : $self->fatal("faile to craete file.");
}

sub visit_hash {
  my ($self, $hash) = @_;
  foreach my $key (keys %$hash) {
    my $data = $hash->{$key};
    if (ref $data eq 'CODE') {
      my (@values) = ($data->($self->{_config}));
      foreach my $v (@values) {
        if (ref $v eq 'REF') {
          if (ref $$v eq 'CODE') {
            $v = $$v = $$v->($self->{_config});;
          } else {
            $v = $$v;
          }
        }
      }
      $data = join "", @values;
    }
    $hash->{$key} = $data;
  }
  return $hash;
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
