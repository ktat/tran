package Tran::Repository::Translation::ModulePodJpArticles;

use warnings;
use strict;
use Tran::Util -common, -list, -file, -prompt, -debug, -pod;
use base qw/Tran::Repository::Translation::JprpArticles/;

__PACKAGE__->one_dir;

use File::Slurp qw(write_file);
sub path_format { return "%n" }

sub copy_option {
  return {
#          target_path => 'lib',
#          omit_path   => 'lib',
#          contents_filter => \&pm2pod,
#          name_filter     => \&pm2pod_name,
         };
}

sub _config {
  my $self = shift;
  return
    {
     '010_directory' => sub { my $self = shift; return (\$self->{vcs}->{wd}, '/docs/articles/') },
     '000_vcs' => {
                   wd   => ask("directry you've cloned for module-pod-jp-articles translation", sub {-d $_[0] ? 1 : 0}),
                   user => ask("your github account name", sub {1}),
             },
    };
}

1;

=head1 NAME

Tran::Repository::Translation::ModulePodJpArticles

=head1 AUTHOR

Ktat, C<< <ktat at cpan.org> >>

=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2013 Ktat.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Tran

