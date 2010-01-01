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

  my $charset = $self->_charset(delete $header{charset}, \%header, \$body);
  sendmail(Email::MIME->create(attributes => \%attributes,
                               ($charset ? 'body_str'   : 'body'  ), $body,
                               ($charset ? 'header_str' : 'header'), [%header]));
}

sub _charset {
  my($self, $charset, $header, $body) = @_;
  $charset ||= '';
  if ($charset =~ /iso[-_]2022[-_]jp/o or $charset =~ /\bjis$/o) {
    $charset = '';
    my $i = 0;
    foreach my $key (keys %$header) {
      $header->{$key} = Encode::encode('MIME-Header-ISO_2022_JP', $header->{$key});
    }
    $header->{'conetnt_type'} = 'text/plain; charset=iso-2022-jp';
    $header->{'encoding'} = '7bit';
    Encode::from_to($$body, "utf8", 'jis');
  } elsif ($charset) {
    $header->{'conetnt_type'} = 'text/plain';
    $header->{'encoding'} = 'base64';
  }
  return $charset;
}

1;

=head1 NAME

Tran::Notify::Email

=head1 SYNOPSIS

in config.yml:

 notify:
   perldocjp:
     # use Tran::Notify::Email
     class: Email
     # parameter to pass Email class
     from: 'from@example.com'
     to: 'to@example.com'
     template_directory: /home/user/.tran/template/perldocjp/

 repository:
   # ...
   translation:
     jprp-modules:
       # ...
       notify: perldocjp

=head1 OPTION

=head2 template_directory

  template_directory: /home/user/.tran/template/perldocjp/

put files correspond to command name under the directory.
For example.

 /home/user/.tran/template/perldocjp/start

Its content is:

 Subject: [RFC] start translation of %n version %v
 charset: jis
 
 Hi
 
 I've started to translate %n version %v.
 
  -- 
 Kato Atsushi (ktat)

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
