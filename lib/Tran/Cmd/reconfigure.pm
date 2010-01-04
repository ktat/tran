package Tran::Cmd::reconfigure;

use warnings;
use strict;
use Tran::Util -common, -string, -debug, -prompt;
use Tran::Cmd -command;
use Tran::Config;
use base qw/Data::Visitor/;

sub abstract { 'recofigure config file'; }

sub run {
  my ($self, $opt, $args) = @_;
  my $config_dir = $ENV{HOME} . '/.tran';
  my $config = "$config_dir/config.yml";

  unless (-e $config) {
    $self->fatal("config file does not exist. use init command at first.");
  }

  unless(@$args) {
    $self->fatal("need argument(s)");
  }

  my $c = Tran::Config->new($config);
  my %config = %{$c->{config}};

  my $target_config = \%config;
  my $target_class = 'Tran';
  foreach my $class (@$args) {
    $target_class .= '::' . camelize($class);
    $class = decamelize($class);
    $target_config = $target_config->{$class};
  }

  foreach my $class (Tran->plugins) {
    next unless $class =~m{^$target_class};

    if ($class->can('_config')) {
      $self->info("start to recofnigure $class");
      my $_config = $class->_config;
      $self->{_config} = $_config;
      $self->{_target_config} = $target_config;
      $self->visit($_config);
      $self->info("finish configuring $class");
    }
  }
  %{$c->{config}} = %config;
  $c->save ? $self->info("file is created.") : $self->fatal("faile to craete file.");
}

sub yours_or_default {
  my ($key, $yours, $default) = @_;
  my $answer = prompt
    ("use your seting for $key? (y = $yours, n = $default)",
     sub { my $answer = shift; return ($answer eq 'y' or $answer eq 'n') ? 1 : 0;});
  return $answer eq 'y' ? $yours : $default;
}

sub confirm_change {
  my ($key, $yours) = @_;
  return prompt("you want to change the value of $key ?(y/n) ($yours)",
                sub {return ($_[0] eq 'y' or $_[0] eq 'n')}, -yn, -default => 'n') eq 'y' ? 1 : 0;
}

sub visit_hash {
  my ($self, $hash) = @_;
  foreach my $key (keys %$hash) {
    my $data = $hash->{$key};
    my $org = $self->{_target_config};
    if (ref $data eq "HASH") {
      $self->{_target_config} = $org->{$key};
      $self->visit_hash($data);
      $self->{_target_config} = $org;
    } elsif (ref $data eq 'CODE') {
      if (confirm_change($key, $org->{$key}) == 0) {
        $data = $org->{$key};
      } else {
        my (@values) = ($data->($self->{_config}));
        my $code;
        $code = pop @values if $values[-1] eq 'CODE';
        foreach my $v (@values) {
          if (ref $v eq 'REF' or ref $v eq 'SCALAR') {
            if (ref $$v eq 'CODE') {
              if (confirm_change($key, $org->{$key}) == 0) {
                $v = $$v = $$v->($self->{_config}) || $org->{$key};
              } else {
                $v = $$v = $org->{$key};
              }
            } elsif ($$v ne $org->{$key}) {
              $v = yours_or_default($key, $org->{$key}, $$v);
            } else {
              $v = $$v;
            }
          }
        }
        unless ($code) {
          $data = join "", @values;
          $data =~s{/+}{/}g;
        } else {
          $data = $code->(@values);
        }
      }
    } elsif ($org->{$key} ne $data) {
      $data = yours_or_default($key, $org->{$key}, $data);
    }
    $org->{$key} = $hash->{$key} = $data;
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
