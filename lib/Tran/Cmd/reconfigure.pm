package Tran::Cmd::reconfigure;

use warnings;
use strict;
use Tran::Util -common, -string, -debug, -prompt;
use Tran::Cmd -command;
use Tran::Config;
use base qw/Data::Visitor/;

sub abstract { 'reconfigure config file'; }

sub validate_args {
  my $self = shift;
  $self->usage_error("need arguemnt(s)") if @{$_[1]} < 1;
}

sub usage_desc {
  "tran reconfigure [item] [item]";
}

sub run {
  my ($self, $opt, $args) = @_;
  my $config_dir = $ENV{HOME} . '/.tran';
  my $config = "$config_dir/config.yml";

  unless (-e $config) {
    $self->usage_error("config file does not exist. use init command at first.");
  }

  my $c = Tran::Config->new($config);
  my %config = %{$c->{config}};

  my $target_config = \%config;
  my $target_class = 'Tran';
  foreach my $class (@$args) {
    $target_class .= '::' . camelize($class);
    $class = decamelize($class);
    $target_config = $target_config->{$class} ||= {};
  }

  foreach my $class (sort Tran->plugins) {
    next unless $class eq $target_class;

    if ($class->can('_config') and %{$class->_config}) {
      local $@;
      eval "require $class";
      if ($@) {
        $self->info("skip reconfigure $class($@)");
        next;
      }
      $self->info("start to reconfigure $class");
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
    ("use your setting for $key? (y = $yours, n = $default)", sub { 1 }, -yn);
  return $answer eq 'y' ? $yours : $default;
}

sub confirm_change {
  my ($key, $yours) = @_;
  $yours ||= '';
  $key =~s{^\d+_}{};
  return prompt("you want to change the value of $key ?(y/n) ($yours)",
                sub { 1 }, -yn, -default => 'n') eq 'y' ? 1 : 0;
}

sub _exec_code {
  my ($code, $config, $key, $org) = @_;
  my @values = $code->($config);
  my $join_code;
  $join_code = pop @values if ref $values[-1] eq 'CODE';
  foreach my $v (@values) {
    if (ref $v eq 'REF' or ref $v eq 'SCALAR') {
      if (ref $$v eq 'PROMPT') {
        if (confirm_change($key, $org) == 0) {
          $v = $$v = $$v->($config) || $org;
        } else {
          $v = $$v = _exec_code($$v, $config, $key, $org);
        }
      } elsif (ref $$v eq 'CODE') {
        $v = $$v = _exec_code($$v, $config, $key, $org);
      } else {
        $v = $$v;
      }
    }
  }
  my $data;
  unless ($join_code) {
    $data = join "", @values;
    $data =~s{/+}{/}g;
  } else {
    $data = $code->(@values);
  }
  return $data;
}

sub visit_hash {
  my ($self, $hash) = @_;
  foreach my $key (sort keys %$hash) {
    my $data = $hash->{$key};
    my $org = $self->{_target_config};
    my $org_key = $key;
    $org_key =~s{^\d+_}{};
    if (defined ref $data) {
      if (ref $data eq "HASH") {
        $self->{_target_config} = $org->{$org_key};
        $self->visit_hash($data);
        $self->{_target_config} = $org;
      } elsif (ref $data eq 'PROMPT') {
        if (confirm_change($key, $org->{$org_key}) == 0) {
          $data = $org->{$org_key};
        } else {
          $data = _exec_code($data, $self->{_config}, $key, $org->{$org_key});
        }
      } elsif (ref $data eq 'CODE') {
        $data = _exec_code($data, $self->{_config}, $key, $org->{$org_key});
      }
    } elsif ($org->{$key} ne $data) {
      $data = yours_or_default($key, $org->{$org_key}, $data);
    }
    $org->{$org_key} = $hash->{$org_key} = $data;
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
