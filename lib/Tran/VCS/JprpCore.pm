package Tran::VCS::JprpCore;

use strict;
use Tran::Util -common, -file;
use base qw/Tran::VCS::JprpModules/;
use Cvs::Simple;
use Cwd qw/cwd/;

sub new {
  my $class = shift;
  my %opt = @_;
  my $o = $class->SUPER::new(%opt);
  $o->{path} = 'perl/';
  return $o;
}

=head1 NAME

Tran::VCS::JprpCore

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


