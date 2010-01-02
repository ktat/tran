package Tran::VCS;

use warnings;
use strict;
use Tran::Util -base;
use VCI;

sub new {
  my $class = shift;
  my %self = @_;
  bless \%self => $class;
}

sub connect {
  my $self = shift;
  my $vci = VCI->connect(type => $self->{type},
                         repo => $self->{repo},
                        );
  return $self->{project} = $vci->get_project(name => $self->{project});
}

sub project {
  my $self = shift;
  return $self->{project};
}

sub add_files { die "implement it in subclass" }

sub commit { die "implement it in subclass" }

sub finish_commit { die "implement it in subclass" }

=head1 NAME

Tran::VCS

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


