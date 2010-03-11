package Tran::Notify::Twitter;

use warnings;
use strict;
use version;
use Tran::Util -prompt;
use Net::Twitter;
use base qw/Tran::Notify/;

sub notify {
  my ($self, $cmd, $target, $version) = @_;
  my $nt = Net::Twitter->new
    (
     traits   => [qw/API::REST/],
     username => $self->{account},
     password => $self->{password},
    ) or return;
  my $message = $self->{message};

  $message =~s{%c}{$cmd}g;
  $message =~s{%n}{$target}g;
  $message =~s{%v}{$version}g;
  $nt->update($message);
}

sub _config {
  return
    {
     class => 'Twitter',
     '000_account'  => bless(sub {prompt("your twitter account", sub {1})}, 'PROMPT'),
     '010_password' => bless(sub {prompt("your twitter password", sub {1})}, 'PROMPT'),
     '020_message'  => bless(sub {prompt("tweet message", sub {1}, -d=> "'%c translattion %n %v")}, 'PROMPT'),
    }
}

1;

=head1 NAME

Tran::Notify::Twitter -- notify to twitter

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
