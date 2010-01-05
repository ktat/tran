package Tran::Util;

use strict;
use Util::Any -Base;
use Clone qw/clone/;

our $Utils = {
              %$Util::Any::Utils,
              '-common' =>  ['Tran::Util::Base'],
              '-file' =>  ['File::Slurp', 'File::Find', 'File::Copy'],
              '-prompt' => {'IO::Prompt' =>
                            { prompt =>
                              sub {
                                sub {
                                  my $message = shift;
                                  my $check   = shift || sub {1};
                                  my @opt = @_;
                                  my $answer;
                                PROMPT:
                                  {
                                    $answer = IO::Prompt::prompt($message . ": ", @opt);
                                    $answer->{value} ||= '';
                                    my $r = $check->($answer->{value});
                                    last PROMPT if $r;

                                    if (not $r) {
                                      warn "$answer->{value} is invalid!\n";
                                      redo PROMPT;
                                    } elsif (not $answer->{value}) {
                                      warn "required!\n";
                                      redo PROMPT;
                                    }
                                  }
                                  return $answer->{value};
                                }
                              }
                            }
                           },
              '-string' => {
                            'String::CamelCase',
                            {
                             camelize => sub {
                               sub {
                                 my $str = shift;
                                 $str = String::CamelCase::camelize($str);
                                 $str =~s{\-}{}go;
                                 return $str;
                               }
                             },
                             decamelize => sub {
                               sub {
                                 my $str = shift;
                                 $str = String::CamelCase::decamelize($str);
                                 $str =~s{_}{-}go;
                                 return $str;
                               }
                             }
                            }
                           }
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
