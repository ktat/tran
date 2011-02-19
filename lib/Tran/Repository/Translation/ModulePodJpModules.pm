package Tran::Repository::Translation::ModulePodJpModules;

use warnings;
use strict;
use Tran::Util -common, -list, -prompt, -pod, -file;
use File::Find;
use version;
use parent qw/Tran::Repository::Translation::JprpModules/;

sub path_format { return "%n-%v" }

sub copy_option {
  return {
          ignore_path     => ['t', 'inc'],
          # see Tran::Util
          contents_filter => \&pm2pod,
          name_filter     => \&pm2pod_name,
         };
}

sub files {
  my $self = shift;
  return grep !m{/\.git/}, $self->SUPER::files(@_);
}

sub _start_hook { }

sub _config {
  my $self = shift;
  return
    {
     '010_directory' => sub { my $self = shift; return (\$self->{vcs}->{wd}, '/docs/modules/') },
     '000_vcs' => {
                   wd   => bless(sub { prompt("directry you've cloned for module-pod-jp-modules translation", sub {-d $_[0] ? 1 : 0}) }, 'PROMPT'),
                   user => bless(sub { prompt("your github account name", sub {1})}, 'PROMPT'),
             },
    };
}

1;

=head1 NAME

Tran::Repository::Translation::ModulePodJpModules

=head1 Config

  repository:
    original:
      directory: /home/ktat/.tran/original/
    translation:
      module-pod-jp-modules:
        directory: /home/ktat/git/github/module-pod-jp/docs/modules/
        vcs:
          user: ktat
          wd: /home/ktat/git/github/module-pod-jp/
  ...
  resource:
    cpan:
      translation: module-pod-jp-modules
  ...

=head1 AUTHOR

Ktat, C<< <ktat at cpan.org> >>

=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2011 Ktat.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Tran
