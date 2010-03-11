package Tran::Repository::Translation::JprpCore;

use warnings;
use strict;
use Tran::Util -common, -prompt;
use version;
use base qw/Tran::Repository::Translation::JprpModules/;

sub path_format { return "%v" }

sub has_target {
  my $self = shift;
  return -d $self->directory ? 1 : 0;
}

sub copy_option {
  my $self = shift;
  my $opt = $self->SUPER::copy_option;
  $opt->{omit_path} = 'pod';
  $opt->{exchange_path} = sub {
    my ($self, $f, $original_path, $translation_path) = @_;
    return unless $f =~m{^/?lib/.+\.pm};
    local $@;
    eval {
      require "$original_path/$f";
    };
    unless ($@) {
      $f =~s{^/?lib/}{};
      $f =~s{/}{::}g;
      $f =~s{\.pm$}{};
      my $version = $f->VERSION;
      $f =~s{::}{-}g;
      return "$translation_path/../../modules/$f-$version";
    }
  };
  $opt;
}

sub get_versions {
  my ($self, $target) = @_;
  my $name = $self->target_path($target);
  die if @_ != 2;
  return if exists $self->{versions}->{$name};

  my @versions;
  if (opendir my $d, $self->directory) {
    foreach my $version (grep /^[\d\.]+$/, readdir $d) {
      push @versions, version->new($version);
    }
    closedir $d;
  } else {
    $self->debug(sprintf "directory is not found : %s", $self->directory);
  }
  return $self->{versions}->{$name} = [sort {$a cmp $b} @versions];
}

sub _config {
  my $self = shift;
  return
    {
     '000_vcs' => {
             wd => bless(sub { prompt("directory you've checkouted for JPRP cvs repository",
                                sub {
                                  if (-d shift(@_) . '/CVS') {
                                    return 1
                                  } else {
                                    $self->warn("directory is not found or not directory CVS checkouted");
                                    return 0;
                                  }
                                }
                               ) }, "PROMPT"),
                  },
     '010_directory' => sub { my $self = shift; return(\($self->{vcs}->{wd}), '/docs/perl/')  },
    };
}

1;

=head1 NAME

Tran::Repository::Translation::JprpCore

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
