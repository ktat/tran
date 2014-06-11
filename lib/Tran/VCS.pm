package Tran::VCS;

use warnings;
use strict;
use Tran::Util -common, -file;
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

sub config {
  my $self = shift;
  return $self->{config};
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
  chdir($self->wd) or Carp::confess "cannot change directory to " . $self->wd . " : "  . $!;
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

sub relative_path {
  my ($self, $path) = @_;
  return if not defined $path or $path eq '';
  my $wd = quotemeta($self->{wd});
  $path =~s{^$wd/?}{};
  return $path;
}

=head1 NAME

Tran::VCS - implementation of version control system for translation

=head1 METHODS

=head2 add_files

=head2 commit

=head2 connect

=head2 files

=head2 finish_commit

=head2 msg

=head2 new

=head2 wd

=head2 relative_path

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


