package Tran::VCS::Jpa;

use strict;
use Tran::Util -common;
use base qw/Tran::VCS/;
use Git::Class;

sub connect {
  my ($self, $target) = @_;
  my $git = Git::Class::Cmd->new(die_on_error => 1, verbose => 1);
  return $git;
}

sub wd {
  my $self = shift;
  return $self->{wd} . '/'. $self->{plus_path};
}

sub checkout_target {
  my ($self, $target_path, $version) = @_;
  $self->_method
    (sub {
       my $git = shift;
       $target_path .= '-Doc-JA';
       my $module = $self->relative_path($target_path);
       my $uri = "git://github.com/jpa/$module.git";
       $self->{plus_path} = $module;
       local $@;
       eval {
         $git->clone($uri);
       };
       return $@ ? 0 : 1;
     });
}

sub update {
  my ($self, $path) = @_;
  $self->{plus_path} = $self->relative_path($path);
  $self->_method
    (
     sub {
       my $git = shift;
       $git->git({}, 'pull');
     });
}

sub add_files {
  my ($self, $path) = @_;
  $self->{plus_path} = $self->relative_path($path);
  $self->_method
    (
     sub {
       my ($git) = @_;
       $git->git({}, 'add', "./");
       $git->commit("./", {message => $self->msg('add_files')});
     }
    );
}

sub commit {
  my ($self, $path) = @_;
  $self->{plus_path} = $self->relative_path($path);
  $self->_method
    (
     sub {
       my ($git) = @_;
       $git->commit({message => $self->msg('commit')});
     }
    );
}

sub relative_path {
  my ($self, $path) = @_;
  my $wd = quotemeta($self->{wd});
  $path =~s{^$wd/?}{};
  return $path;
}

=head1 NAME

Tran::VCS::Jpa

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


