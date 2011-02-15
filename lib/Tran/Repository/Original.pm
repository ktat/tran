package Tran::Repository::Original;

use strict;
use Tran::Util -debug, -common, -prompt;
use File::Find qw/find/;
use base qw/Tran::Repository/;

sub get_versions {
  my ($self, $target) = @_;
  my $name = $self->target_path($target);
  die if @_ != 2;
  return if exists $self->{versions}->{$name};

  my @versions;
  if (opendir my $d, $self->directory . '/' . $name) {
    foreach my $version (grep /^[\d\.]+(?:_\d+)?$/, readdir $d) {
      next if $version =~ m{^\.\.?$};
      push @versions, version->new($version);
    }
    closedir $d;
  } else {
    $self->debug(sprintf "directory is not found : %s/%s", $self->directory, $name);
    return;
  }
  return $self->{versions}->{$name} = [sort {$a cmp $b} @versions];
}

sub resource {
  my ($self, $resource) = @_;
  $self->{resource} = $resource if @_ == 2;
  return $self->{resource};
}

sub resource_directory {
  my ($self, $resource) = @_;
  Carp::croak("set resource at first") unless $self->resource;
  return join "/", $self->directory, lc($self->resource) , '';
}

sub target_path {
  my ($self, $target) = @_;
  Carp::croak("set resource at first") unless $self->resource;
  Carp::croak("taget name is required") if @_ == 1;
  return join '/', lc($self->resource), $self->SUPER::target_path($target);
}

sub has_target {
  my ($self, $target) = @_;
  my $target_path = $self->target_path($target);
  return  -d $self->directory . '/' . $target_path ? 1 : 0;
}

sub _config {
  return
    {
     directory => "$ENV{HOME}/.tran/original/",
    };
}

1;

=head1 NAME

Tran::Repository::Original

=head1 METHODS

=head2 get_versions

 $r->get_versions($target);

return target's version(version objects) as array ref.

=head2 has_target

 $r->has_target($target);

If original repository has target, return 1;

=head2 resource

 $r->resource;
 $r->resource($resource);

get/set resource object.

=head2 resource_directory

 $r->resource_directory;

return resource directory.
need to set resource before using this.

=head2 target_path

 $r->target_path($target);

return target path.
need to set resource before using this.

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
