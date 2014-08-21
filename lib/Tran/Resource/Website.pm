package Tran::Resource::Website;

use warnings;
use strict;
use base qw/Tran::Resource/;
use Tran::Util -common, -debug, -list, -file;
use File::Path qw/make_path/;
use version;
use Time::Piece;
use Furl;
use Web::Query;
use JSON::XS;

sub _get_content_from_url {
  my ($self, $url) = @_;
  my $furl = Furl->new();
  my $res = $furl->get($url);

  my $content;
  my $scrape_option = $self->config->{scraper}->{$url} || $self->config->{scraper}->{all};
  if  ($self->config->{scrper}->{use_default}) {
    $scrape_option = {selector => 'body'};
  }
  if ($scrape_option) {
    if (my $scraper = $scrape_option->{scraper}) {
      $content = $scraper->scrape($res->content);
    } elsif (my $selector = $scrape_option->{selector}) {
      my $c = wq($res->content)->find($selector)->contents;
      $content = _filter_and_merge_html($c, $res->content);
    }
  }
  if (not $content) {
    $content = $res->content;
  }
  return $content;
}

sub _filter_and_merge_html {
  my ($content, $whole_html) = @_;
  my ($title)    = wq($whole_html)->filter('title')->as_html;
  my ($desc)     = wq($whole_html)->filter('title[name="description"]')->as_html;
  my ($keywords) = wq($whole_html)->filter('title[name="keywords"]')->as_html;
  ($title)    = $title    =~ m{>(.+)<};
  ($desc)     = $desc     =~ m{content\s*=\s*(?:["'])(.+)\1};
  ($keywords) = $keywords =~ m{content\s*=\s*(?:["'])(.+)\1};
  return <<_HTML_
<html>
<head>
<title>$title</title>
<meta name="description" content="$desc">
<meta name="keywords"    content="$keywords">
</head>
<body>
$content
</body>
</html>
_HTML_
}

# get and store pages in previous version directory
sub _store_content_of_previous {
  my ($self, $target, $root_path, $previous_version, $version) = @_;
  my ($path, $filename) = url2path($target);

  opendir my $dir, path_join $root_path, $previous_version;
  my @files;
  while (my $file = readdir $dir) {
    next if $file =~ /^\.\.?$/;
    next if $file eq '.tran_translation' or $file eq $filename;

    $self->debug("$file will be copied.");

    push @files, $file;
  }
  close $dir;
  $target =~s{/[^/]+$}{};

  my $furl = Furl->new();
  foreach my $file (@files) {
    my $url = $target . '/' . $file;
    my $content = $self->_get_content_from_url($url);
    if ($content) {
      my $store_path = path_join $root_path, $version, $file;
      write_file($store_path, $content) or die "$! $store_path";
      $self->info("$url is stored to $store_path.");
    }
  }
}

sub _store_content {
  my ($self, $target, $content, $version) = @_;
  my $original_dir = $self->original_repository->resource_directory;
  my ($path, $filename) = url2path($target);
  my $root_path = path_join $original_dir, $path;

  my @version_dirs;
  if (-d $root_path) {
    opendir my $dir, "$root_path";
    @version_dirs =  sort(grep /^\d+\.\d+\.\d+$/, readdir $dir);
    closedir $dir;
  }
  $path = path_join $root_path, $version;

  if (-d $path) {
    if($version_dirs[1]) {
      $self->_store_content_of_previous($target, $root_path, $version_dirs[1], $version);
    }
  } elsif ($version_dirs[0]) {
    make_path($path) or die ($path) unless -d $path;
    $self->_store_content_of_previous($target, $root_path, $version_dirs[0], $version);
  }

  make_path($path) if ! -d $path;
  my $store_path = path_join $path, $filename;
  write_file($store_path, $content) or die "$! : $target > $path/$filename";
  $self->info("$target is stored to $store_path.");
}

sub get {
  my ($self, $target) = @_;
  my $t = localtime;
  my $version = $t->strftime('%Y.%m.%d');
  my $content = $self->_get_content_from_url($target);
  $self->_store_content($target, $content, $version);
  return (1, $self->target_translation($target), version->parse($version));
}

sub target_path {
  my ($self, $target) = @_;
  my ($path, $filename) = url2path($target);
  return $path;
}

sub _config {
  return
    {
     scraper => {
                 'use_default' => "1 or 0",
                 'URL' => {
                           scraper  => 'YourScraper',
                           selector => 'selector for Web::Query',
                          }
                }
    }
}

=head1 NAME

Tran::Resource::Website - for Website

=head1 SYNOPSIS

 tran start -r website -t jprp-articles http://qntm.org/files/perl/perl.html

=head1 AUTHOR

Ktat, C<< <ktat at cpan.org> >>

=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2013- Ktat.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Tran

