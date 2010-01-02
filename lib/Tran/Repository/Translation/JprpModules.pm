package Tran::Repository::Translation::JprpModules;

use warnings;
use strict;
use Tran::Util -base;
use version;
use base qw/Tran::Repository::Translation/;

sub path_format { return "%n-%v" }

sub get_versions {
  my ($self, $target) = @_;
  my $name = $self->target_path($target);
  die if @_ != 2;
  return if exists $self->{versions}->{$name};

  my @versions;
  if (opendir my $d, $self->directory) {
    foreach my $name_version (grep /^$name\-[\d\.]+$/, readdir $d) {
      my ($version) = ($name_version =~ m{^$name\-([\d\.]+)$});
      push @versions, version->new($version);
    }
    closedir $d;
  } else {
    $self->debug(sprintf "directory is not found : %s", $self->directory);
  }
  return $self->{versions}->{$name} = [sort {$a cmp $b} @versions];
}

sub files {
  my $self = shift;
  return grep {!m{/CVS/} and !m{/CVSROOT/}} $self->SUPER::files(@_);
}

sub has_target {
  my ($self, $target) = @_;
  my $target_path = $self->target_path($target);
  if (opendir my $dir, $self->directory) {
    return any {/^$target_path\-[\d\.]+$/} readdir $dir ? 1 : 0;
  } else {
    $self->fatal("cannot open directory");
  }
}

1;

=head1 NAME

Tran::Repository::Translation::JprpModules

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
