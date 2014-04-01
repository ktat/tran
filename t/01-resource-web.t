use Test::More;
use strict;
use lib qw(lib t/lib);
use File::Path qw/remove_tree/;
use File::Slurp qw/slurp/;
use Cwd qw/cwd/;

use Tran;

my $tran = Tran->new('./t/_tran/config.yml');
my $resource = $tran->resource('Website');
ok $resource, 'website';

if (-d "./t/.tran/original/web/") {
  remove_tree './t/.tran/original/web/';
}
subtest 'get web page' => sub {
  my ($sec, $min, $hour, $mday, $mon, $year) = localtime(time);
  my $date = sprintf "%04d.%02d.%02d", $year += 1900, ++$mon, $mday;
  my ($result, $translation_repository, $version) = $resource->get('http://search.cpan.org/');
  ok $result, "got target";
  is $translation_repository, 'module-pod-jp-articles', 'translation repository';

  my $cwd = cwd();
  my $index_file = $cwd . '/t/.tran/original/website/search.cpan.org/'. $date . '/index.html';
  ok -e $index_file, 'got HTML';
  ok slurp($index_file) =~ m{The CPAN Search Site}, "HTML contains 'The CPAN Search Site'";
};

done_testing;
