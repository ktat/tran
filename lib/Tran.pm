package Tran;

use warnings;
use strict;
use Tran::Util -debug, -string, -common;
use Class::Inspector;
use Module::Pluggable search_path => ['Tran'], require => 1;

__PACKAGE__->plugins;

sub new {
  my ($class, $config_file) = @_;
  my $config = Tran::Config->new($config_file);
  my $log_opt = ($config->{config}{log} ||= {class => 'Stderr', level => 'info'});
  my $log_class = __PACKAGE__ . '::Log::' . camelize(delete $log_opt->{class});
  my $log = $log_class->new(%$log_opt);
  my $self = bless {config => $config, log => $log}, $class;
  $self->{resources} = {};

  my $original_repository = Tran::Repository::Original->new
    (config => $config->original_repository, log => $log);

  foreach my $kind (keys %{$config->resources}) {
    $kind = camelize($kind);
    my $class = "Tran::Resources::$kind";
    $self->{resources}->{$kind} = $class->new
      (root => $self,
       log  => $log,
       original => $original_repository,
       config => $config->resources->{decamelize($kind)},
       encoding => $self->encoding,
      );
  }

  foreach my $key (keys %{$self->config->translation_repository}) {
    my $class = camelize($key);
    $class = 'Tran::Repository::Translation::' . $class;
    $class = Class::Inspector->loaded($class) ? $class : 'Tran::Repository::Translation';
    $self->{translation}->{$key} = $class->new
      (
       name     => $key,
       log      => $log,
       config   => $self->config->translation_repository->{$key},
       original => $original_repository,
      );
  }

  foreach my $key (keys %{$self->config->notify}) {
    my $config = $self->config->notify($key);
    my $class = __PACKAGE__ . '::Notify::' . camelize($config->{class});
    $self->{notify}->{$key} = $class->new(%$config, log => $log);
  }

  return $self;
}

sub log {
  my $self = shift;
  $self->{log};
}

sub encoding {
  my $self = shift;
  return $self->config->{encoding} || 'utf8';
}

sub resource {
  my ($self, $resource) = @_;
  return $self->{resources}->{$resource}  if exists $self->{resources}->{$resource};
  $self->fatal("no such resource: $resource");
}

sub resources {
  my $self = shift;
  $self->{resources};
}

sub config {
  my $self = shift;
  return $self->{config};
}

sub original {
  my $self = shift;
  die join "--", caller;
  return $self->{original};
}

sub translation {
  my ($self, $name) = @_;
  return @_ == 2 ? $self->{translation}->{$name} :  $self->{translation};
}

sub notify {
  my $self = shift;
  my ($name, @args) = @_;
  if (defined $name) {
    for my $n (ref $name eq 'ARRAY' ? @$name : $name) {
      $self->fatal("unkown notify name: $n") unless $self->{notify}->{$n};
      $self->{notify}->{$n}->notify(@args);
    }
  }
}

=head1 NAME

Tran - Version Control for Translation

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Quick summary of what the module does.

start translation:

 % tran start CPAN Moose

finish translation(not yet implement):

 % tran finish CPAN Moose

=head1 Config file

~/.tran/config.yml

 ---
 tempolary_dir: /home/ktat/.tran/tmp/
 log:
   class: Stderr
   level: debug

 notify:
   perldocjp:
     class: Email
     from : 'from@example.com'
     to   : 'to@example.com'
     template_directory: /home/ktat/.tran/template/perldocjp/
 
 repository:
   original:
     directory: /home/ktat/.tran/original/
 
   translation:
     jprp-modules:
       directory: /home/ktat/cvs/perldocjp/docs/modules/
       path_format: "%n-%v"
 
     jpa:
       directory: /home/ktat/git/github/jpa-translation/
       path_format: "%n-Doc-JA"
 
 resources:
   CPAN:
     # default translation repository
     translation: jprp-modules
     metafile: /home/ktat/.cpan/Metadata
     target_only:
       - '*.pm'
       - '*.pod'
       - README
       - Changes
     # if target_only is specified, target_ignore is ignored
     target_ignore:
       - '*.t'
     target_directory:
       - lib
     # not default translation repository
     targets:
       Moose:
         translation: jpa
       MooseX::Getopt:
         translation: jpa

=head1 AUTHOR

Ktat, C<< <ktat at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-tran at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tran>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    man tran

You can also look for information at:

=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2010 Ktat.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Tran
