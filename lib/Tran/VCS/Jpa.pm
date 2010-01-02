package Tran::VCS::Jpa;

use strict;
use Tran::Util -base;
use base qw/Tran::VCS/;

sub new {
  my $class = shift;
  my %opt = @_;
  my $o = $class->SUPER::new(
                             repo    => $opt{repo},
                             type    => 'Git',
                            );
  return $o;
}

sub connect {
  my ($self, $target) = @_;
  my $vci = VCI->connect(type => $self->{type},
                         repo => $self->{repo},
                        );
  return $self->{project} = $vci->get_project(name => "$target-Doc-JA");
}

sub add_files {
  my ($self, $target, $version) = @_;
  my $p = $self->connect;
  
}

sub commit {
  my ($self, $target, $version) = @_;
  my $p = $self->connect;
  
}

sub finish_commit {
  my ($self, $target, $version) = @_;
  my $p = $self->connect;
}

=head1 NAME

Tran::VCS::Jpa

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


