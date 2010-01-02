package Tran::VCS;

use warnings;
use strict;
use Tran::Util -base, -file;
use Cwd qw/cwd/;

my %MSG = (
           update    => 'update files',
           commit    => 'commit by tran',
           add_files => 'add files & commit by tran'
          );

sub new {
  my $class = shift;
  my %self = @_;
  $self{cwd} = cwd;
  bless \%self => $class;
}

sub connect { die "implement it in subclass" }

sub add_files { die "implement it in subclass" }

sub commit { die "implement it in subclass" }

sub finish_commit { die "implement it in subclass" }

sub files {
  my ($self, $path) = @_;
  my @f;
  find({
        wanted => sub {
          my $f = $File::Find::name;
          push @f, $f;
        },
        nochdir => 1,
       },
       $path);
  return @f;
}

sub _method {
  my ($self, $sub, @argv) = @_;
  chdir($self->wd);
  my $vcs = $self->connect;
  my $r;
  if (@_ > 1) {
    $r = $sub->($vcs, @argv);
  }
  chdir($self->{cwd});
  return $r;
}

sub wd {
  my $self = shift;
  return $self->{wd};
}

sub msg {
  my ($self, $method) = @_;
  return $MSG{$method};
}

=head1 NAME

Tran::VCS

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


