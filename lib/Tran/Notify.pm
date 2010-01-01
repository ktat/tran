package Tran::Notify;

use warnings;
use strict;
use version;
use Tran::Util -base;

sub new {
  my ($class, %self) = @_;
  bless \%self => $class;
}

1;

=head1 NAME

Tran::Notify

=head1 SYNOPSIS

 notify:
  class: NotificationClass
  param1: value1
  param2: value2
  ...

see Tran::Notify::* classes.

=head1 SEE ALSO

Tran::Notify::Email

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
