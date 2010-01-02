package Tran::VCS::JprpModules;

use strict;
use Tran::Util -base;
use base qw/Tran::VCS/;

sub new {
  my $class = shift;
  my %opt = @_;
  my $o = $class->SUPER::new(
                             repo    => ":ext:$opt{vcs_user}\@cvs.sourceforge.jp:/cvsroot/perldocjp",
                             type    => 'Cvs',
                             project => '.',
                            );
  return $o;
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

Tran::VCS::JprpModules

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


