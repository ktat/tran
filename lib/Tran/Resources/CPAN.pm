package Tran::Resources::CPAN;

use warnings;
use strict;
use base qw/Tran::Resources/;
use File::Path ();
use Cwd qw/cwd/;
use Tran::Util -debug, -list, -base;
use File::Path qw/make_path/;
use LWP::Simple ();
use Storable qw/retrieve/;
use Archive::Tar;
use IO::String;
use IO::Uncompress::Gunzip;
use version;

my $metadata;

sub get_module_info {
  my ($self, $target, $version) = @_;
  my $metadata ||= retrieve($self->config->{metafile});
  my $module_info = $metadata->{'CPAN::Module'}{$target} or die "cannot find url for $target";
  unless ($version) {
    $version = $module_info->{CPAN_VERSION};
    ($version) = $module_info->{CPAN_FILE} =~m{-([\d\.]+)\.tar\.gz};
  } else {
    $module_info->{CPAN_FILE} =~ s{-([\d\.]+)\.tar\.gz}{-$version.tar.gz};
  }
  return $module_info->{CPAN_FILE}, $version;
}

sub get {
  my ($self, $target, $version) = @_;
  my $target_path = $target;
  $target_path =~s{::}{-}g;

  my $config = $self->config;

  my $url;
  ($url, $version) = $self->get_module_info($target) unless $version;
  $self->debug("$target $version : $url");
  return ($target_path, $self->target_translation($target), version->new($version))
    if $self->original_repository->has_version($target_path, $version);

  ($url) = $self->get_module_info($target, $version) unless $url;

  $url = 'http://search.cpan.org/CPAN/authors/id/' . $url;
  $self->debug("get from $url");
  my $targz = LWP::Simple::get($url) or $self->fatal("cannot get $url");
  my $fh = IO::Uncompress::Gunzip->new(IO::String->new(\$targz)) or die;
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
  my $original_dir = $self->original_repository->directory;
  foreach my $file ($tar->get_files(@files)) {
    my $name = $original_dir . $file->full_path;
    $name =~s{/$target_path-([^/]+)/}{/$target_path/$1/};
    my ($out_dir) = $name =~m{^(.+)/};
    if (not -e $out_dir) {
      make_path($out_dir) or die $out_dir;
    }
    if ($file->name =~ m{\.pm$}) {
      $name =~ s{\.pm}{.pod};
      $self->debug("write file: $name");
      open my $fh, ">", $name or die "cannot write $name";
      $self->pm2pod($file->get_content, $fh);
      close $fh;
    } elsif($file->get_content) {
      $self->debug("write file: $name");
      open my $fh, ">", $name or die "cannot write $name";
      print $fh $file->get_content;
      close $fh;
    }
  }
  $self->original_repository->reset;
  return $target_path, $self->target_translation($target), version->new($version), \@files;
}

# from Pod::Perldoc::ToPod
sub pm2pod {
  my($self, $content, $outfh) = @_;
  my $cut_mode = 1;

  # A hack for finding things between =foo and =cut, inclusive
  local $_;
  foreach (split /[\n\r]/, $content) {
    if(  m/^=(\w+)/s ) {
      if($cut_mode = ($1 eq 'cut')) {
        print $outfh "\n=cut\n\n" or die "Can't print to $outfh: $!";
         # Pass thru the =cut line with some harmless
         #  (and occasionally helpful) padding
      }
    }
    next if $cut_mode;
    print $outfh $_, "\n" or die "Can't print to $outfh: $!";
  }
  return;
}

1;

=head1 NAME

Tran::Resources::CPAN

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
