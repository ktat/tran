package Tran::Notify::Email;

use warnings;
use strict;
use version;
use Tran::Util -file, -debug;
use base qw/Tran::Notify/;
use Email::MIME;
use Email::Sender::Simple qw/sendmail/;
use Encode;

sub notify {
  my ($self, $cmd, $target, $version) = @_;
  my $c = slurp($self->{template_directory} . '/' . $cmd);
  $c =~ s{%c}{$cmd}g;
  $c =~ s{%n}{$target}g;
  $c =~ s{%v}{$version}g;
  $self->send_email($c);
}

# send_email([From => 'from@example.com'], {'content_type' => 'text/plain'}, \@parts);
sub send_email {
  my ($self, $c) = @_;
  my $i = 0;
  my %header;
  my %attributes;
  my ($header, $body) = (split /[\r\n][\r\n]/, $c, 2);
  foreach my $p (split /[\r\n]/, $header) {
    my ($key, $value)  = split /:/, $p, 2;
    $value =~s{\s*}{};
    $header{$key} = $value;
  }

  $header{ucfirst $_} = $self->{$_} foreach qw/from to/;

  my $charset = $self->_charset(delete $header{charset}, \%header);
  sendmail(Email::MIME->create(attributes => \%attributes,
                               ($charset ? 'body_str'   : 'body'  ), $body,
                               ($charset ? 'header_str' : 'header'), [%header]));
}

sub _charset {
  my($self, $charset, $header) = @_;
  $charset ||= '';
  if ($charset =~ /iso[-_]2022[-_]jp/o or $charset =~ /\bjis$/o) {
    $charset = '';
    my $i = 0;
    foreach my $key (keys %$header) {
      $header->{$key} = Encode::encode('MIME-Header-ISO_2022_JP', $header->{$key});
    }
    $header->{'conetnt_type'} = 'text/plain; charset=iso-2022-jp';
    $header->{'encoding'} = '7bit';
  } elsif ($charset) {
    $header->{'conetnt_type'} = 'text/plain';
    $header->{'encoding'} = 'base64';
  }
  return $charset;
}

1;

=head1 NAME

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
