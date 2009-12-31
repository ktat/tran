package Tran::Util;

use strict;
use Util::Any -Base;
use Clone qw/clone/;

our $Utils = {
              %$Util::Any::Utils,
              '-base' =>  ['Tran::Util::Base'],
              '-file' =>  ['File::Slurp', 'File::Find', 'File::Copy'],
             };

1;

=head1 NAME

Tran::Util

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
