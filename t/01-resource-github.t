use Test::More;
use strict;
use lib qw(lib t/lib);
use File::Path qw/remove_tree/;
use File::Slurp qw/slurp/;
use Cwd qw/cwd/;

use Tran;

my $tran = Tran->new('./t/_tran/config.yml');
my $resource = $tran->resource('Github');
ok $resource, 'github';

if (-d "./t/.tran/original/github/") {
  remove_tree './t/.tran/original/github/';
}
subtest 'get github web page' => sub {
  my ($sec, $min, $hour, $mday, $mon, $year) = localtime(time);
  my $date = sprintf "%04d.%02d.%02d", $year += 1900, ++$mon, $mday;
  my ($result, $translation_repository, $version) = $resource->get('https://github.com/ktat/tran/blob/master/README.md');
  ok $result, "got target";
  is $translation_repository, 'module-pod-jp-articles', 'translation repository';

  my $cwd = cwd();
  my $index_file = $cwd . '/t/.tran/original/github/github.com/ktat/tran/blob/master/'. $date . '/README.md';
  ok -e $index_file, 'got HTML';
  ok slurp($index_file) =~ m{Tran::Manual - manual of tran}, "HTML contains 'Tran::Manual - manual of tran'";
};

done_testing;
