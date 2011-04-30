package Tran::Util;

use strict;
use Tran::UtilAny -Base;
use Clone qw/clone/;

our $Utils = {
              %$Tran::UtilAny::Utils,
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
                                    $message .= ": " unless $message =~ m{[\?:]\s*$};
                                    $answer = IO::Prompt::prompt($message, @opt);
                                    $answer->{value} ||= '';
                                    my $r = $check->($answer->{value});
                                    last PROMPT if $r;

                                    if (not $r) {
                                      warn "'$answer->{value}' is invalid!\n";
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
                           },
              '-pod' => {
                         'Tran::Util',
                         {
                          pm2pod_name => sub {
                            sub { my ($self, $name) = @_; $name =~ s{\.pm}{\.pod}; return $name}
                          },
                          pm2pod => sub {
                            sub {
                              # from Pod::Perldoc::ToPod
                              my($self, $name, $content) = @_;
                              return if ($name !~ m{\.pm} and $name !~ m{\.pod$});
                              my $pod = '';
                              my $cut_mode = 1;
                              # A hack for finding things between =foo and =cut, inclusive
                              local $_;
                              foreach (split /[\n\r]/, $content) {
                                if(  m/^=(\w+)/s ) {
                                  if($cut_mode = ($1 eq 'cut')) {
                                    $pod .= "\n=cut\n\n";
                                    # Pass thru the =cut line with some harmless
                                    #  (and occasionally helpful) padding
                                  }
                                }
                                next if $cut_mode;
                                $pod .= $_ . "\n";
                              }
                              if ($pod) {
                                $pod = sprintf("=encoding %s\n\n", $self->encoding) . $pod;
                              }
                              return $pod;
                            }
                          }
                         }
                        },
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
