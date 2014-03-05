package Tran::Profile;

use strict;
use Tran::Util -prompt;

sub _config {
  return
    {
     '00_name'  => ask("your name:",   sub { $_[0] ? 1 : 0}),
     '10_email' => ask("your email:",  sub { $_[0] ? 1 : 0}),
    };
}

=head1 NAME

Tran::Profile

=head1 SYNOPSIS

 profile:
   name: ...
   email: ...

=head1 SEE ALSO

Tran::Profile

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

