package Tran::Repository::Translation::Jpa;

use warnings;
use strict;
use Tran::Util -list, -file, -prompt, -debug, -pod;
use base qw/Tran::Repository::Translation/;
use File::Slurp qw(write_file);

sub path_format { return "%n-Doc-JA" }

sub copy_option {
  return {
          target_path => 'lib',
          omit_path   => 'lib',
          contents_filter => \&pm2pod,
          name_filter     => \&pm2pod_name,
         };
}

sub get_versions {
  # get only one version ..., need to use git(?) to fetch branches
  my ($self, $target) = @_;
  Carp::croak("target is required as first argument")  if @_ != 2;
  my $name = $self->target_path($target);
  return if exists $self->{versions}->{$name};

  my $translation_target_dir = $self->path_of($name);
  my $meta_file = $translation_target_dir . '/META.yml';

  my @versions;
  my $c;
  local $@;
  eval {$c = slurp($meta_file)};
  unless ($@) {
    if (my ($version) = $c =~m{^version:\s*(.+)$}m) {
      $self->debug("read version from: $meta_file ($version)");
      push @versions, version->new($version);
    } else {
      $self->debug("cannot read version information from metafile: $meta_file");
    }
  } else {
    $self->debug("cannot open metafile: $meta_file");
  }
  return $self->{versions}->{$name} = [sort {$a cmp $b} @versions];
}

sub update_version_info {
  my ($self, $target, $version) = @_;
  my $target_path = $self->target_path($target);
  my $target_dir = $self->path_of($target_path, $version) . '/';
  my $meta = $target_dir . '/META.yml';
  if (-e $meta) {
    my $c = slurp($meta);
    $c =~s{^version:(.+)}{version: $version};
    write_file($meta, $c);
    $self->info("meta file($meta) is updated.");
  } else {
    write_file($meta, "version: $version\ndistribution: $target_path");
    $self->info("meta file($meta) is created.");
  }
}

sub has_target {
  my ($self, $target) = @_;
  my $target_path = $self->target_path($target);
  return -d $self->directory . '/' . $target_path . '-Doc-JA' ? 1 : 0;
}

sub _config {
  my $self = shift;
  return
    {
     vcs => {
             wd   => bless(sub { prompt("directory you've cloned for jpa translation", sub {-d shift || 0}) }, 'PROMPT'),
             user => bless(sub { prompt("your github account name", sub {1})}, 'PROMPT'),
            },
     directory => sub { my $self = shift; return(\($self->{vcs}->{wd})) },
    };
}

1;

=head1 NAME

Tran::Repository::Translation::Jpa

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
