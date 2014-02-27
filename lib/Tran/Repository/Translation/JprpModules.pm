package Tran::Repository::Translation::JprpModules;

use warnings;
use strict;
use Tran::Util -common, -list, -prompt, -pod, -file;
use File::Find;
use version;
use base qw/Tran::Repository::Translation/;

sub path_format { return "%n-%v" }

sub copy_option {
  return {
          ignore_path     => ['t', 'xt', 'inc'],
          # see Tran::Util
          contents_filter => \&pm2pod,
          name_filter     => \&pm2pod_name,
         };
}

sub get_versions {
  my ($self, $target) = @_;
  my $name = $self->target_path($target);
  die if @_ != 2;

  return if exists $self->{versions}->{$name};

  my @versions;
  if (opendir my $d, $self->directory) {
    foreach my $name_version (grep /^$name\-v?[\d\.]+(?:_\d+)?$/, readdir $d) {
      my ($version) = ($name_version =~ m{^$name\-(v?[\d\.]+(?:_\d+)?)$});
      push @versions, version->new($version);
    }
    closedir $d;
  } else {
    $self->debug(sprintf "directory is not found : %s", $self->directory);
  }

  return $self->{versions}->{$name} = [sort {$a cmp $b} @versions];
}

sub files {
  my $self = shift;
  return grep {!m{/CVS/} and !m{/CVSROOT/}} $self->SUPER::files(@_);
}

sub has_target {
  my ($self, $target) = @_;
  my $target_path = $self->target_path($target);
  if (opendir my $dir, $self->directory) {
    return any {/^$target_path\-v?[\d\.]+(?:_\d+)?$/} readdir $dir ? 1 : 0;
  } else {
    $self->fatal(sprintf "cannot open directory %s", $self->directory);
  }
}

sub now {
  my ($sec, $min, $hour, $day, $month, $year) = localtime;
  $year += 1900;
  $month++;
  return sprintf "%d-%02d-%02d %02d:%02d:%02d", $year, $month, $day, $hour, $min, $sec;
}

sub _start_hook {
  my ($self, $target, $version, $prompt) = @_;
  my ($file, $xml) = $self->make_xml($target, $version);
  if (-e $file) {
    if (lc(prompt("overwrite $file ?", undef, -ynd => 'n')) eq 'y') {
      write_file($file, $xml);
      $self->debug("meta file is written: $file");
    }
  } else {
    write_file($file, $xml);
    $self->debug("meta file is written: $file");
  }
}

sub make_xml {
  my ($self, $target, $version) = @_;
  my $target_path = $self->target_path($target);
  my $now = now();
  my $name  = $self->tran->config->profile->{name};
  my $email = $self->tran->config->profile->{email};
  my $path  = $self->path_of($target, $version);
  my @files;
  File::Find::find({wanted => sub {push @files, $File::Find::name if $File::Find::name =~m{\.pod$}}}, $path);
  my $files = join "\n", map {
    s{^$path/?}{};
    my $file_path = $_;
    my $file_name = $_;
    $file_name =~s{^/?lib/}{};
    $file_name =~s{/}{::}g;
    $file_name =~s{\.pod}{};
    <<__FILES__;
                <ファイル>
                        <パス>$file_path</パス>
                        <名称>$file_name</名称>
                        <説明></説明>
                </ファイル>
__FILES__
             } @files;
    my $xml = <<__XML__;
<?xml version="1.0" encoding="euc-jp" ?> 
<翻訳物>
  <パッケージ>
          <名称>$target_path</名称>
          <バージョン>$target_path-$version</バージョン>
  </パッケージ>
  <説明>$target_path-$version の日本語訳</説明>
  <言語>ja-jp</言語>
        <日時>
                <作成日時>$now</作成日時>
                <更新日時>$now</更新日時>
        </日時>
        <翻訳グループ>
                <翻訳者>
                        <名前>$name</名前>
                        <連絡先>$email</連絡先>
                </翻訳者>
        </翻訳グループ>
        <内容物>
$files
        </内容物>
</翻訳物>
__XML__
    Encode::from_to($xml, "utf8", "euc-jp");
    return "$path/../../../meta/modules/$target_path-$version.xml", $xml;
}

sub _config {
  my $self = shift;
  return
    {
     '010_directory' => sub { my $self = shift; return (\$self->{vcs}->{wd}, '/docs/modules/') },
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
                               ) }, 'PROMPT'),
             },
    };
}

1;

=head1 NAME

Tran::Repository::Translation::JprpModules

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
