package Tran::Repository::Translation::JprpCore;

use warnings;
use strict;
use Tran::Util -base;
use version;
use base qw/Tran::Repository::Translation/;

sub get_versions {
  my ($self, $name) = @_;
  die if @_ != 2;
  return if exists $self->{versions}->{$name};

  my @versions;
  if (opendir my $d, $self->directory) {
    foreach my $version (grep /^[\d\.]+$/, readdir $d) {
      push @versions, version->new($version);
    }
    closedir $d;
  } else {
    $self->debug(sprintf "directory is not found : %s", $self->directory);
  }
  return $self->{versions}->{$name} = [sort {$a cmp $b} @versions];
}

1;

=head1 NAME

Tran::Repository::Translation::JprpCore

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
