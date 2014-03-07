package Tran::Resource::Cpan;

use warnings;
use JSON::XS;
use strict;
use base qw/Tran::Resource/;
use File::Path ();
use Cwd qw/cwd/;
use Tran::Util -debug, -list, -common, -file;
use File::Path qw/make_path/;
use LWP::Simple ();
use Storable qw/retrieve/;
use Archive::Tar;
use IO::String;
use IO::Uncompress::Gunzip;
use IO::Uncompress::Bunzip2;
use version;
use MetaCPAN::API;
use Module::CoreList;

my $metadata;

sub get_module_info_from_metacpan {
  my ($self, $target, $version, $_target) = @_;
  my ($download_url);
  my $mcpan = MetaCPAN::API->new;
  my $distribution_name = $target;
  $distribution_name =~ s{::}{-}g;
  if ($version) {
    if (my $distv = eval {$mcpan->release(distribution => $distribution_name)}) {
      $distv = $mcpan->release(author => $distv->{author}, release => $distribution_name . '-' . $version);
      return @{$distv}{qw/download_url version/};
    }
  } else {
    if (my $distv = eval {$mcpan->release(distribution => $distribution_name)}) {
      return @{$distv}{qw/download_url version/};
    } else {
      return;
    }
  }
}

sub check_module_corelist_version {
  my ($self) = @_;

  return if not $self->{module_core_list_version_checking}++;

  my $mcpan = MetaCPAN::API->new;
  my $module = $mcpan->release( distribution => 'Module-CoreList');
  if (version->new($module->{version}) > version->new(Module::CoreList->VERSION)) {
    $self->warn(sprintf 'Module::CoreList version(%s) is older than the latest(%s)',
		Module::CoreList->VERSION, $module->{version});
  }
}

sub get_module_info_from_metacpan_with_corelist {
  my ($self, $target, $version) = @_;

  my ($perl_version, $got_version);
  foreach my $_perl_version (sort {$b cmp $a} keys %Module::CoreList::version) {
    if (exists $Module::CoreList::version{$_perl_version}->{$target}) {
      $perl_version = $_perl_version;
      $got_version  = $Module::CoreList::version{$_perl_version}->{$target};
      last if not $version or $got_version eq $version;
    }
  }

  return if not $perl_version;

  # dummy version number for undef version
  $got_version ||= '0.0';
  my $pod = eval {
    my $release = format_perl_version($perl_version);

    my $metacpan = MetaCPAN::API->new;
    $metacpan->pod(
		   'module'	  => $target,
		   'release'	  => 'perl-' . $release,
		   'content-type' => 'text/x-pod',
		  );
  };

  $self->warn($@) if $@;

  return ($pod, $got_version);
}

sub get_core_document_from_metacpan {
  my ($self, $target, $version) = @_;
  my ($perl_version);

  if (not $version) {
    foreach my $_perl_version (sort {$b cmp $a} keys %Module::CoreList::version) {
      $perl_version = format_perl_version($_perl_version);
      last;
    }
  } elsif ($version =~ m{^5\.\d+$}) {
    if ($Module::CoreList::version{$version}) {
      $perl_version = format_perl_version($version);
    } else {
      $self->warn('not perl version:' . $version);
    }
  } elsif ($Module::CoreList::version{numify_version($version)}) {
    $perl_version = $version;
  }

  return if not $perl_version;

  my $pod = eval {
    my $metacpan = MetaCPAN::API->new;
    $metacpan->pod(
		   'module'	  => $target,
		   'release'	  => 'perl-' . $perl_version,
		   'content-type' => 'text/x-pod',
		  );
  };

  $self->warn($@) if $@;

  # for compatibility of JPRP directory name
  $perl_version =~s{^v}{};

  return ($pod, $perl_version);
}

# these 3 subroutines are copied from corelist command
{
    my $have_version_pm;

    sub have_version_pm {
        return $have_version_pm if defined $have_version_pm;
        return $have_version_pm = eval { require version; 1 };
    }

    sub format_perl_version {
      my $v = shift;
      return $v if $v < 5.006 or !have_version_pm;
      return version->new($v)->normal;
    }

    sub numify_version {
        my $ver = shift;
        if ($ver =~ /\..+\./) {
            have_version_pm()
                or die "You need to install version.pm to use dotted version numbers\n";
            $ver = version->new($ver)->numify;
        }
        $ver += 0;
        return $ver;
    }
}

sub _resolve_target_url_version {
  my ($self, $_target, $_target_path, $version) = @_;
  my ($target, $target_path, $url_or_file) = ($_target, $_target_path, '');

  if ($version and $version =~m{^http}) {
    my ($_version) = $version =~ m{\w-(v?[\d.]+(?:_\d+)?)\.tar\.(?:gz|bz2)$};
    return ($_target, $_target_path, $version, $_version)
  }
  ($url_or_file, $version) = $self->get_module_info_from_metacpan($target, $version);
  return ($target, $target_path, $url_or_file, $version);
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

  my ($pod, $_target, $_target_path, $url, $_version);

  my $is_coredoc = 0;
  if ($target =~m{^perl\w+$}) {
    # 1st. search core document
    $self->check_module_corelist_version();
    ($pod, $_version) =  $self->get_core_document_from_metacpan($target, $version);
  }
  if ($pod) {
    $is_coredoc = 1;
  } else {
    # 2nd. search with MetaCPAN
    ($_target, $_target_path, $url, $_version)
      = $self->_resolve_target_url_version($target, $target_path, $version);

    if (not $url) {
      # 3rd. search with MetaCPAN with Perl version
      $self->check_module_corelist_version();
      ($pod, $_version) = $self->get_module_info_from_metacpan_with_corelist($target, $version);
      if (not $pod) {
	$self->fatal("cannot find $target");
      }
    }
  }

  $version = $_version;

  if ($is_coredoc) {
    if ($self->original_repository->has_version('perl', $version, "pod/$target.pod")) {
      # implementation depends on jprp-core directory structure.
      return (0, $self->target_translation($target), version->new($version), ['perl', "$target.pod"]);
    }
  } elsif ($self->original_repository->has_version($_target_path || $target_path, $version)) {
    return (0, ($self->target_translation($target), version->new($version)));
  }

  if ($pod) {
    my $original_dir = $self->original_repository->resource_directory;
    my ($name, $file_path) = regularlize_perl_dist_modules($target_path);
    my ($path, $file_name) = $file_path =~m{^(?:(.+)\-)*(\w+)$};
    $file_name .= '.pod';

    if ($is_coredoc) {
      $path = path_join $original_dir, 'perl', $version, 'pod';
    } else {
      $path = path_join $original_dir, $name, $version , 'lib', $path;
    }

    make_path $path if not -d $path;

    write_file("$path/$file_name", $pod) or die "cannot write $path/$file_name";
    if ($is_coredoc) {
      return (1, $self->target_translation($target), version->new($version), ['perl', "$path/$file_name"]);
    } else {
      return (1, $self->target_translation($target), version->new($version));
    }
  } else {
    return (1, $self->get_file_and_extract($_target || $target, $_target_path, $target_path, $_version, $version, $url));
  }
}

sub get_file_and_extract {
  my ($self, $target, $_target_path, $target_path, $_version, $version, $url) = @_;

  my $config = $self->config;

  $self->debug($target . " $version : $url");
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
        or $self->fatal("cannot get $url \n           $backpan_url\n           $backpan_url2\n\tsearch google for 'site:backpan.cpan.org $_target_path-$_version.tar.gz / $backpan_url2'");
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

  $self->debug("target files are:\n" . join "\n", @files);

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
          eval {($file_name, $version) = $self->get_module_info_from_metacpan($module)};

          if ($@ or (defined $file and $file !~ m{/perl-})) {
            $self->warn("$module is skipped.");
            next FILE;
          }
        }
        ($path, $name) = ("$original_dir/$name/$VERSION/$path" =~ m{^(.+)/([^/+]+)$});
	unless (-d $path) {
	  $self->debug("make path: $path");
	  make_path($path) or die ($path);
	}
        $self->debug("write file: $path/$name");
	write_file("$path/$name", $file->get_content) or die "cannot write $path/$name";
      }
    } else {
      $name =~s{^([\w:]+)\.pm\-(v?[\d.]+(?:_\d+)?/)}{$1-$2};
      $name =~s{^$target_path-([^/]+)/}{$target_path/$1/}i or $self->fatal("target '$target_path' is not included in '$name'. don't you typo?");
      $name = $original_dir . '/' . $name;
      my ($out_dir) = $name =~m{^(.+)/};
      if (not -e $out_dir) {
        make_path($out_dir) or die $out_dir;
      }
      $self->debug("write file: $name");
      write_file($name, $file->get_content) or die "cannot write $name";
    }
  }
  $self->original_repository->reset;
  return ($self->target_translation($target), version->new($version));
}

sub _config {
  return
    {
     translation => 'jprp-modules',
     target_only => [
                     '*.pm',
                     '*.pod',
                     '^[^.]+$'
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

=head1 CAUTION

If you want to start translation of perl core document or the modules in perl distribution.
you should use the latest version of Module::CoreList.

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
