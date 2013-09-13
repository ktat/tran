package Tran::Resource::Cpan;

use warnings;
use JSON::XS;
use strict;
use base qw/Tran::Resource/;
use File::Path ();
use Cwd qw/cwd/;
use Tran::Util -debug, -list, -common;
use File::Path qw/make_path/;
use LWP::Simple ();
use Storable qw/retrieve/;
use Archive::Tar;
use IO::String;
use IO::Uncompress::Gunzip;
use IO::Uncompress::Bunzip2;
use version;

my $metadata;

sub get_module_info_from_cpan {
  my ($self, $target, $version, $_target) = @_;
  $_target ||= '';
  unless ($metadata) {
    local $@;
    # CPAN::Index->reload;
    eval {
      $metadata = retrieve($self->config->{metafile});
    };
    $self->fatal("cannot read metafile:" . $self->config->{metafile}) if $@;
  }
  my $module_info = $metadata->{'CPAN::Module'}{$target};
  unless ($module_info) {
    $target =~s{-}{::}g;
    $module_info = $metadata->{'CPAN::Module'}{$target} or die "cannot find url for $target";
  }
  if (not $version) {
    ($version) = $module_info->{CPAN_FILE} =~m{-([\d\.]+(?:_\d+)?)\.tar\.(gz|bz2)};
  } elsif ($_target ne 'perl' and $self->_is_perl($module_info->{CPAN_FILE})) {
    ($version) = $module_info->{CPAN_FILE} =~m{-([\d\.]+(?:_\d+)?)\.tar\.(gz|bz2)};
  } else {
    $module_info->{CPAN_FILE} =~ s{-(?:[\d\.]+(?:_\d+)?)\.tar\.(gz|bz2)}{-$version.tar.$1};
  }
  return $module_info->{CPAN_FILE}, $version;
}

# from FrePan. if failed, from CPAN
sub get_module_info {
  my ($self, $target, $version, $_target) = @_;
  my $download_url;
  if ($version) {
    return $self->get_module_info_from_cpan($target, $version, $_target);
  } else {
    $_target ||= '';
    $target =~s{::}{-}g;
    my $url = 'http://frepan.org/dist/' . $target;
    my $c = LWP::Simple::get($url) || '';
    if ($c =~m{"(http://cpan\.cpantesters\.org/authors/id/[^"]+?)"}
     or $c =~m{"(http://search\.cpan\.org/CPAN/authors/id/[^"]+?)"}
       ) {
      $download_url = $1;
      ($version) = $download_url =~m{-([\d\.]+(?:_\d+)?)\.tar\.(gz|bz2)};
    } else {
      return $self->get_module_info_from_cpan($target, $version, $_target);
    }
  }
  $version or die "cannot find url for $target";
  return $download_url, $version;
}

sub _resolve_target_url_version {
  my ($self, $_target, $_target_path, $version) = @_;
  my ($target, $target_path, $url_or_file) = ($_target, $_target_path, '');

  if ($version and $version =~m{^http}) {
    my ($_version) = $version =~ m{\w-(v?[\d.]+(?:_\d+)?)\.tar\.(?:gz|bz2)$};
    return ($_target, $_target_path, $version, $_version)
  }

  if ($target eq 'perl') {
    ($url_or_file, $version) = $self->get_module_info('B', $version, $target);
  } else {
    ($url_or_file, $version) = $self->get_module_info($target, $version);
    if ($self->_is_perl($url_or_file)) {
      $self->info("$target is Perl core module. find version from original directory.");
      if (my $versions = $self->original_repository->get_versions($target)) {
        $version = $versions->[-1];
        $self->info("$target is $version in original directory");
        return ($target, $target_path, '', $version);
      } else {
        $self->fatal("$target is not in original directory. do 'tran start cpan perl'");
      }
    }
  }

  if ($target eq 'perl') {
    my $_version = $version;
    if (version->new($_version) >= version->new("5.11.0")) {
      $url_or_file = "http://www.cpan.org/src/5.0/perl-$_version.tar.bz2";
    } else {
      $url_or_file = "http://www.cpan.org/src/5.0/perl-$_version.tar.gz";
    }
  }
  return ($target, $target_path, $url_or_file, $version);
}

sub _is_perl {
  my ($self, $url_or_file) = @_;
  if ($url_or_file and $url_or_file =~ '/perl\-\d+\.\d+\.\d+\.tar\.\w+$') {
    return 1;
  } else {
    return 0;
  }
}

sub regularlize_perl_dist_modules {
  my $name = shift;
  $name =~s{^\w+/perl-([^/]+/)}{};
  # perl 5.18.0
  # dist/B-Deparse/Deparse.pm
  # perl5.10.0
  # ext/SDBM_File/SDBM_File.pm -> SDBM_File.pm
  # ext/MIME/Base64/Base64.pm  -> MIME/Base64.pm
  $name =~ s{^(?:ext|dist)/(.+/)([^/]+)/\2}{$1$2};
  $name =~ s{^(?:ext|dist)/([^/]+)/\1}{$1};
  # perl 5.11.2
  # ext/PerlIO-encoding/encoding.pm -> PerlIO/encoding.pm
  # ext/Sys-Hostname/Hostname.pm    -> Sys/Hostname.pm
  $name =~ s{^(?:ext|dist)/(\w+)-(\w+)/\2}{$1/$2};
  my $path = $name;
  $name =~s{^lib/}{};
  $name =~s{/}{-}g;
  $name =~s{\.(?:pm|pod)$}{};
  return ($name, $path);
}

sub get {
  my ($self, $target, $version) = @_;
  my $target_path = $target;
  $target_path =~s{::}{-}g;

  my $config = $self->config;
  my ($_target, $_target_path, $url, $_version)
    = $self->_resolve_target_url_version($target, $target_path, $version);
  $version = $_version;

  return ($self->target_translation($target), version->new($version))
    if $self->original_repository->has_version($_target_path || $target_path, $version);

  $self->debug(($_target || $target) . " $version : $url");
  $url = 'http://search.cpan.org/CPAN/authors/id/' . $url if $url !~ '^http://';
  $self->fatal("cannot determin url for $target") unless $url;

  $self->debug("get $url");
  my $targz;
  unless ($targz = LWP::Simple::get($url)) {
    my $file_path = "$_target_path-$_version.tar.gz";
    $file_path =~s{^([^-]+)-}{$1/$1-};
    $url = my $backpan_url = "http://backpan.cpan.org/modules/by-module/$file_path";
    $self->debug("get $url");
    unless ($targz = LWP::Simple::get($backpan_url)) {
      my $backpan_url2 = $backpan_url;
      $backpan_url2 =~s{-(v?[\d\.]+(?:_\d+)?\.tar\.gz)$}{.pm-$1};
      $url = $backpan_url2;
      $self->debug("get $url");
      $targz = LWP::Simple::get($backpan_url2)
        or $self->fatal("cannot get $url \n           $backpan_url\n           $backpan_url2\n\tsearch goole for 'site:backpan.cpan.org $_target_path-$_version.tar.gz / $backpan_url2'");
    }
  }
  $self->debug("got $url");
  my $fh;
  $self->debug("start to extract file.");
  if ($url =~m{tar\.gz$}) {
    $fh = IO::Uncompress::Gunzip->new(IO::String->new(\$targz))  or $self->fatal("cannot extract file");
  } else {
    $fh = IO::Uncompress::Bunzip2->new(IO::String->new(\$targz)) or $self->fatal("cannot extract file");
  }
  my $tar = Archive::Tar->new($fh);
  my @files;
  my @target_dir = @{$config->{target_directory} || []};
  if (my $only = $config->{target_only}) {
    foreach (@$only) {
      s{\*}{.*}g;
    }
    foreach my $file ($tar->list_files) {
      next if @target_dir and ! any {$file =~ m{^[^/]+/$_/}} @target_dir;
      push @files, $file if any {$file =~ m{^[^/]*/$_$}} @$only;
    }
  } elsif (my $ignore = $config->{target_ignore}) {
    foreach (@$ignore) {
      s/\*/.*/g;
    }
    foreach my $file ($tar->list_files) {
      next if @target_dir and ! any {$file =~ m{^[^/]*/$_}} @target_dir;
      push @files, $file unless any {$file =~ m{^[^/]*/$_$}} @$ignore;
    }
  }

  my $cwd = cwd();
  my $original_dir = $self->original_repository->resource_directory;

 FILE:
  foreach my $file (sort {$a cmp $b} $tar->get_files(@files)) {
    my $name = $file->full_path;
    if ($target eq 'perl' and  $name =~ s{^perl-[\d.]+(?:_\d+)?/((?:lib|ext/[^/]+)/.+\.(?:pm|pod))$}{$1}) {
      my $content = $file->get_content;
      my $VERSION = 0;
      if (not $VERSION and $content =~ m{(\$(?:\w+::)?VERSION\s*=[^;]+;)}s) {
        $VERSION = eval "$1";
      }
      if ($VERSION) {
        my $path;
        ($name, $path) = regularlize_perl_dist_modules($name);
        {
          my $module = $name;
          $module =~s{-}{::}g;
          my ($file_name, $version);
          eval {($file_name, $version) = $self->get_module_info($module)};

          if ($@ or (defined $file and $file !~ m{/perl-})) {
            $self->warn("$module is skipped.");
            next FILE;
          }
        }
        ($path, $name) = ("$original_dir/$name/$VERSION/$path" =~m{^(.+)/([^/+]+)$});
        make_path($path) or die ($path) unless -d $path;
        $self->debug("write file: $path/$name");
        open my $fh, ">", "$path/$name" or die "cannot write $path/$name";
        print $fh $file->get_content;
        close $fh;
      }
    } else {
      $name =~s{^([\w:]+)\.pm\-([\d.]+(?:_\d+)?/)}{$1-$2};
      $name =~s{^$target_path-([^/]+)/}{$target_path/$1/} or $self->fatal("'$target_path' is not included in '$name'. don't you typo?");
      $name = $original_dir . '/' . $name;
      my ($out_dir) = $name =~m{^(.+)/};
      if (not -e $out_dir) {
        make_path($out_dir) or die $out_dir;
      }
      $self->debug("write file: $name");
      open my $fh, ">", $name or die "cannot write $name";
      print $fh $file->get_content;
      close $fh;
    }
  }
  $self->original_repository->reset;
  return ($self->target_translation($target), version->new($version), \@files);
}

sub _config {
  return
    {
     translation => 'jprp-modules',
     metafile => ("$ENV{HOME}/.local/share/.cpan//Metadata"
                  ? "$ENV{HOME}/.local/share/.cpan//Metadata"
                  : "$ENV{HOME}/.cpan/Metadata"),
     target_only => [
                     '*.pm',
                     '*.pod',
                    ],
     'targets' => {
                   'perl',
                   => {
                       translation => 'jprp-core',
                      },
                   'Moose'
                   => {
                       translation => 'jpa',
                      },
                   'MooseX::Getopt'
                   => {
                       translation => 'jpa',
                      },

                  }
    };
}

=head1 NAME

Tran::Resource::Cpan - for CPAN

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
