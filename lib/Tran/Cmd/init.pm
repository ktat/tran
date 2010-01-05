package Tran::Cmd::init;

use warnings;
use strict;
use Tran::Util -common, -string;
use Tran::Cmd -command;
use Tran::Config;
use base qw/Data::Visitor/;

sub abstract { 'initialize config file'; }

sub opt_spec {
  return (
          ['force|f', "forcely initialize config file" ]
         );
}

sub run {
  my ($self, $opt, $args) = @_;
  my $config_dir = $ENV{HOME} . '/.tran';
  my $config = "$config_dir/config.yml";

  if (-e $config and not $opt->{force}) {
    $self->fatal("config file exists: $config");
  }
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
      $self->info("start to config $class");
      my $_config = $class->_config;
      $self->{_config} = $_config;
      $config = $self->visit($_config);
      $class =~ s{^Tran::}{};
      my (@separate) = map decamelize($_), split /::/, $class;
      my $sub_config = $config{shift @separate} ||= {};
      $sub_config = $sub_config->{$_} ||= {} for @separate;
      %$sub_config = %$config;
      $self->info("finish configuring $class");
    }
  }
  %{$c->{config}} = %config;
  $c->save ? $self->info("file is created.") : $self->fatal("faile to craete file.");
}

sub _exec_code {
  my ($code, $config) = @_;
  my @values = $code->($config);
  my $join_code;
  $join_code = pop @values if ref $values[-1] eq 'CODE';
  foreach my $v (@values) {
    if (ref $v eq 'REF' or ref $v eq 'SCALAR') {
      if (ref $$v eq 'CODE') {
        CORE::warn
        $v = $$v = _exec_code($v, $config);
      } else {
        CORE::warn
        $v = $$v;
      }
    }
  }
  my $data;
  unless ($join_code) {
    $data = join "", @values;
    $data =~s{/+}{/}g;
  } else {
    $data = $join_code->(@values);
  }
  return $data;
}

sub visit_hash {
  my ($self, $hash) = @_;
  foreach my $key (keys %$hash) {
    my $data = $hash->{$key};
    if (ref $data eq "HASH") {
      $self->visit_hash($data);
    } elsif (ref $data eq 'CODE') {
      $data = _exec_code($data, $self->{_config});
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
