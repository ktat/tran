package Tran::Repository::Translation::JprpArticles;

use warnings;
use strict;
use Tran::Util -common, -list, -file, -prompt, -debug, -pod;
use base qw/Tran::Repository::Translation/;

__PACKAGE__->one_dir;

use File::Slurp qw(write_file);
sub path_format { return "%n" }

sub copy_option {
  return {
#          target_path => 'lib',
#          omit_path   => 'lib',
#          contents_filter => \&pm2pod,
#          name_filter     => \&pm2pod_name,
         };
}

sub target_path {
  my ($self, $target) = @_;
  my ($path, $filename) = url2path($target);
  return $path;
}

sub get_versions {
  # get only one version ..., need to use git(?) to fetch branches
  my ($self, $target) = @_;
  Carp::croak("target is required as first argument")  if @_ != 2;
  my $name = $self->target_path($target);
  return if exists $self->{versions}->{$name};

  my $translation_target_dir = $self->path_of($target);
  my $meta_file = $translation_target_dir . '/tran_original_version';

  my @versions;
  my $c;
  local $@;
  my $version;
  if (-e $meta_file) {
    chomp($version = eval { slurp($meta_file) });
    unless ($@) {
      $self->debug("read version from: $meta_file ($version)");
      push @versions, version->new($version);
    } else {
      $self->debug("cannot read version information from version file: $meta_file");
    }
  } else {
    $self->debug("no version file: $meta_file");
  }
  return $self->{versions}->{$name} = [sort {$a cmp $b} @versions];
}

sub update_version_info {
  my ($self, $target, $version) = @_;
  my $target_path = $self->target_path($target);
  my $target_dir = $self->path_of($target, $version) . '/';
  my $meta = $target_dir . '/tran_original_version';
  if (-e $meta) {
    write_file($meta, $version);
    $self->info("meta file($meta) is updated.");
  } else {
    write_file($meta, $version);
    $self->info("meta file($meta) is created.");
  }
}

sub has_target {
  my ($self, $target) = @_;
  my ($path) = $self->target_path($target);

  return -d $self->directory . '/' . $path ? 1 : 0;
}

sub _config {
  my $self = shift;
  return
    {
     '010_directory' => sub { my $self = shift; return (\$self->{vcs}->{wd}, '/docs/articles/') },
     '000_vcs' => {
              wd => bless(sub { prompt("directory you've checkouted for JPRP cvs repository",
                                sub {
                                  if (-d shift(@_) . '/CVS') {
                                    return 1
                                  } else {
                                    $self->warn("directory is not found or not directory CVS checkouted");
                                    return 0;
                                  }
                                }
                               ) }, 'PROMPT'),
             },
    };
}

1;

=head1 NAME

Tran::Repository::Translation::JprpArticlesy

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

