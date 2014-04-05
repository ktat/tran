package Tran::Resource::Github;

use warnings;
use strict;
use base qw/Tran::Resource::Website/;
use Tran::Util -common, -debug, -list, -common;
use File::Path qw/make_path/;
use version;
use Time::Piece;
use Furl;
use Web::Query;

sub _get_content_from_url {
  my ($self, $url) = @_;

  $self->debug("try to get content from $url.");

  if ($url =~ s{^https://github}{https://raw.github}) {
    $url =~ s{/blob/}{/};
  } else {
    $self->abort("only allow http://github.com/... : " . $url);
  }

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

=head1 NAME

Tran::Resource::Github - base class for getting github content with URL

=head1 SYNOPSIS

 tran start -r github https://github.com/tokuhirom/plenv/blob/master/README.md

=head1 DESCRIPTION

This resource is special version of Tran::Resource::Website.
Of course files put on github are managed with git, so you can use Resource::Git instead.
But if you want to translate git resource as just a web site, use this resource.

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
