package Tran::Repository::Original;

use strict;
use Tran::Util -debug, -base, -prompt;
use File::Find qw/find/;
use base qw/Tran::Repository/;

sub get_versions {
  my ($self, $target) = @_;
  my $name = $self->target_path($target);
  die if @_ != 2;
  return if exists $self->{versions}->{$name};

  my @versions;
  if (opendir my $d, $self->directory . '/' . $name) {
    foreach my $version (grep /^[\d\.]+$/, readdir $d) {
      push @versions, version->new($version);
    }
    closedir $d;
  } else {
    $self->debug(sprintf "directory is not found : %s/%s", $self->directory, $name);
  }
  return $self->{versions}->{$name} = [sort {$a cmp $b} @versions];
}

sub has_target {
  my ($self, $target) = @_;
  my $target_path = $self->target_path($target);
  return  -d $self->directory . '/' . $target_path ? 1 : 0;
}

sub _config {
  return
    {
     original => {
                  directory => "$ENV{HOME}/.tran/orginal/",
                 }
    };
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
