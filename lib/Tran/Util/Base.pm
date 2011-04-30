package Tran::Util::Base;

use warnings;
use strict;
use base qw/Exporter/;
use Encode::Guess;
use File::Slurp ();

our @EXPORT_OK =qw/warn error fatal info debug encoding_slurp path_join/;

BEGIN {
  require Tran::Log;
  foreach my $level (keys %Tran::Log::LOG_LEVEL) {
    no strict "refs";
    my $lc_level = lc $level;
    *{__PACKAGE__ . '::' . $lc_level} = sub {
      my ($self, $message) = @_;
      if (not ref $self and $self =~ m{^Tran::}) {
        my $log = Tran::Log::Stderr->new(level => 'warn');
        return $log->warn(@_[1 .. $#_], "\n");
      }
      return Carp::carp(@_) unless ref $self;
      my $log = (ref $self) =~m{^Tran::Cmd} ? $self->app->{log} : $self->{log};
      my $method = lc $level;
      $log->$method($message);
    };
  }
}

sub encoding_slurp {
  my ($file, $enc) = @_;
  my $c = '';
  eval {
    $c = File::Slurp::slurp($file);
  };
  return  unless $c;
  eval {
    $c = Encode::decode("Guess", $c);
    $c = Encode::encode($enc, $c);
  };
  return $c;
}

sub path_join {
  my (@dirs) = @_;
  my $path = join '/', @dirs;
  $path =~ s{//+}{/}g;
  return $path;
}

1;

=head1 NAME

Tran::Util::Base

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
