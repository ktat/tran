package Tran;

use warnings;
use strict;
use Tran::Util -debug, -string, -common, -file;
use Class::Inspector;
use Tran::Log;
use Scalar::Util qw/weaken/;
use Module::Pluggable search_path => ['Tran'], require => 1;

my @RESOURCES;
foreach my $plugin (__PACKAGE__->plugins) {
  if ($plugin =~ m{^Tran::Resource::(.+)$}) {
    push @RESOURCES, $1;
  }
}

sub new {
  my ($class, $config_file) = @_;
  my $config = Tran::Config->new($config_file);
  my $log_opt = ($config->{config}{log} ||= {class => 'Stderr', level => 'info'});
  my $log_class = __PACKAGE__ . '::Log::' . camelize(delete $log_opt->{class});
  my $log = $log_class->new(%$log_opt);
  my $self = bless {config => $config, log => $log}, $class;
  $self->{resource} = {};

  my $original_repository = Tran::Repository::Original->new
    (config => $config->original_repository, log => $log);

  $self->{original} = $original_repository;

  foreach my $kind (@RESOURCES) {
    my $class = "Tran::Resource::$kind";
    $self->{resource}->{$kind} = $class->new
      (
       tran => $self,
       log  => $log,
       original => $original_repository,
       config => $config->resources->{decamelize($kind)},
      );
    weaken $self->{resource}->{$kind}->{tran};
  }
  my $merge_method = delete $self->config->translation_repository->{merge_method} || '';
  foreach my $key (keys %{$self->config->translation_repository}) {
    my $class = camelize($key);
    $class = 'Tran::Repository::Translation::' . $class;
    $class = Class::Inspector->loaded($class) ? $class : 'Tran::Repository::Translation';
    $self->{translation}->{$key} = $class->new
      (
       tran     => $self,
       name     => $key,
       log      => $log,
       config   => $self->config->translation_repository->{$key},
       original => $original_repository,
       encoding => $self->encoding,
       merge_method => $merge_method,
      );
  }

  foreach my $key (keys %{$self->config->notify}) {
    my $config = $self->config->notify($key);
    my $class = __PACKAGE__ . '::Notify::' . camelize($config->{class});
    $self->{notify}->{$key} = $class->new(%$config, log => $log, tran => $self);
  }

  return $self;
}

sub original_repository {
  my $self = shift;
  return $self->{original};
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
  if (defined $resource and exists $self->{resource}->{$resource}) {
    $self->original->resource($resource);
    return $self->{resource}->{$resource};
  }
  $self->fatal("no such resource: $resource");
}

sub resources {
  my $self = shift;
  $self->{resource};
}

sub config {
  my $self = shift;
  return $self->{config};
}

sub original {
  my $self = shift;
  return $self->{original};
}

sub get_sticked_translation {
  my ($self, $target, $resource) = @_;
  my $resource_repository = $self->resource(camelize($resource));
  my $original_repository = $resource_repository->original_repository;

  my $translation_name = '';
  my $translation_file = path_join $original_repository->path_of($target), '.tran_translation';
  if (-e $translation_file) {
    chomp($translation_name = read_file($translation_file));
  }
  return $translation_name;
}

sub stick_translation {
  my ($self, $target, $resource, $translation_name) = @_;
  my $resource_repository = $self->resource(camelize($resource));
  my $original_repository = $resource_repository->original_repository;
  my $translation_file = path_join $original_repository->path_of($target), '.tran_translation';
  write_file($translation_file, $translation_name)  or die "$! : $translation_file";
}

sub translation_repository {
  my ($self, $name) = @_;
  return @_ == 2 ? $self->{translation}->{$name} :  $self->{translation};
}

*translation = \&translation_repository;

sub notify {
  my $self = shift;
  my $prompt;
  $prompt = pop if ref $_[-1] eq 'CODE';
  my ($name, @args) = @_;
  if (defined $name) {
    for my $n (ref $name eq 'ARRAY' ? @$name : $name) {
      local $@;
      unless ($self->{notify}->{$n}) {
        $self->warn("unknown notify name: $n");
      } else {
        next if defined $prompt and not $prompt->($n);
        eval {
          $self->{notify}->{$n}->notify(@args);
        };
        $self->warn("cannot notify: $@") if $@;
      }
    }
  }
}

=head1 NAME

Tran - Version Control for Translation

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 DESCRIPTION

see Tran::Manaual.

=head1 METHODS

=head2 new

 Tran->new("/path/to/config.yml");

constructor.

=head2 log

 $tran->log

return Tran::Log object.

=head2 encoding

 $tran->encoding;

return encoding setting.

=head2 resource

 $tran->resource($resource_name);

return Tran::Resource::* object.

=head2 resources

 $tran->resources;

return hash ref which contains resource name and resource object.

=head2 config

 $tran->config;

return Tran::Config object.

=head2 original_repository

 $tran->original_repository;

return Tran::Repository::Original object.

=head2 original

 $tran->original;

It is as same as original_repository.

=head2 translation_repository

 $tran->translation_repository($translation_name);

return Tran::Repository::Translation::* object.

 $tran->translation_repository;

return hashref which contains translation name and its object.

=head2 notify

 $tran->notify(@notify_names, [ sub { ... }]);

Do notification according to @notify_names.

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

    perldoc Tran::Manual::JA

=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2010 Ktat.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Tran
