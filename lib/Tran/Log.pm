package Tran::Log;

use strict;
use warnings;

our %LOG_LEVEL = (
                 FATAL => 0,
                 ERROR => 1,
                 WARN  => 2,
                 INFO  => 3,
                 DEBUG => 4,
);

sub new {
  my ($class, %opt) = @_;
  $opt{level} = $LOG_LEVEL{uc($opt{level})} || 0;
  bless \%opt, $class;
}

sub level {
  my ($self, $level) = @_;
  $self->{level} = $level if @_ == 2;
  return $self->{level};
}

foreach my $level (keys %LOG_LEVEL) {
  no strict "refs";
  my $lc_level = lc $level;
  *{__PACKAGE__ . '::' . $lc_level} = sub {
    my ($self, $message) = @_;
    if ($self->level >= $LOG_LEVEL{$level}) {
      $message = "[$lc_level] " . $message;
      if ($self->can("_do_log")) {
        my $msg = $self->_do_log($message);
        if ($lc_level eq 'fatal' or $lc_level = 'error') {
          exit 255;
        }
        return $msg;
      } else {
        return $message;
      }
    }
  };
}

1;

=head1 NAME

Tran::Log

=head1 METHOD

=head2 fatal

fatal message

=head2 error

error message

=head2 warn

warn message

=head2 info

info message

=head2 debug

debug message

=head1 SYNOPSYS

 log:
   class: LogSubClass
   level: debug

=head1 COPYRIGHT & LICENSE

Copyright 2009 Ktat, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
