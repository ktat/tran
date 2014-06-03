package Tran::VCS::CVS;

use strict;
use warnings;

use strict;
use Tran::Util -common, -file;
use base qw/Tran::VCS/;
use Cvs::Simple;
use Cwd qw/cwd/;

sub new {
  my $class = shift;
  my %opt = @_;
  return $class->SUPER::new(%opt);
}

sub connect {
  my $self = shift;
  my $cwd = cwd;
  chdir($self->{wd});
  my $cvs = Cvs::Simple->new();
  chdir($cwd);
  return $cvs;
}

sub update {
  my ($self, $path) = @_;
  return $self->_method
    (
     sub {
       my ($cvs) = @_;
       chdir $path if defined $path;
       $cvs->update;
     }
    );
}

sub add_files {
  my ($self, $target_path) = @_;
  my @files = $self->files($target_path);
  return $self->_method
    (
     sub {
       my ($cvs) = @_;
       $cvs->update;
       if (@files) {
         $cvs->add(@files);
         $cvs->commit;
       }
     }
    );
}

sub commit {
  my ($self, $path) = @_;
  return $self->_method
    (
     sub {
       my ($cvs) = @_;
       chdir $path if defined $path;
       $cvs->update;
       $cvs->commit;
     }
    );
}

=head1 NAME

Tran::VCS::Base::CVS

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



1;

