package Tran::Repository::Translation::JprpCore::VCS;

use strict;
use warnings;

use base qw/Tran::VCS::CVS/;

sub config {
  my ($self, %opt) = @_;
  my %self = (
              wd      => $opt{wd},
              path    => 'docs/modules/',
              project => '.',
             );
  $self{repo} = ":ext:$opt{vcs_user}\@cvs.sourceforge.jp:/cvsroot/perldocjp"
    if defined $opt{vcs_user};
  return %self;
}

=head1 NAME

Tran::Repository::Translation::JprpArticles::VCS

=head1 AUTHOR

Ktat, C<< <ktat at cpan.org> >>

=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2014 Ktat.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Tran
