use Test::More;
use strict;
use lib qw(lib t/lib);
use File::Path qw/remove_tree/;
use Cwd qw/cwd/;
use File::Slurp qw/slurp/;

use Tran;

foreach my $dir (qw(t/git_test t/git_clone)) {
  if (-d $dir) {
    remove_tree $dir;
  }
  mkdir $dir or die "cannot mkdir $dir";
}

if ($^O !~ m{linux}i and $^O != m{bsd}i  and $^O != m{darwin}i) {
  plan 'skip_all', "test can be run on Linux/BSD/Mac OS X only.";
  exit 1;
}

my $cwd = cwd();
my $result = system(<<_SHELL_);
(
cd t/git_test/              || exit 1;
git init --bare             || exit 1;
cd -                        || exit 1;
git clone file:///$cwd/t/git_test t/git_clone || exit 1;
cd t/git_clone              || exit 1;
touch README                || exit 1;
git add "README"            || exit 1;
git commit -m "test commit" || exit 1;
git branch 0.1              || exit 1;
git checkout 0.1            || exit 1;
echo 0.1 > README           || exit 1;
git commit -m '0.1' ./      || exit 1;
git branch 0.2              || exit 1;
git checkout 0.2            || exit 1;
echo 0.2 > README           || exit 1;
git commit -m '0.2' ./      || exit 1;
git checkout master         || exit 1;
git push origin master      || exit 1;
git push origin 0.1         || exit 1;
git push origin 0.2         || exit 1;
cd -  || exit 1;
) > /dev/null 2>&1
_SHELL_

is $result, 0, "prepare git repository";

if ($result) {
  plan 'skip_all', "cannot prepare git repository";
  exit 1;
}

if (-d "./t/.tran/original/git/") {
  remove_tree './t/.tran/original/git/';
}

my $tran = Tran->new('./t/_tran/config.yml');
my $resource = $tran->resource('Git');
ok $resource, 'git';
is $resource->target_translation, 'module-pod-jp-articles';

subtest 'get from git 0.1' => sub {
  my $cwd = cwd();
  my ($res, $translation, $version) = $resource->get("file:///$cwd/t/git_test/", 0.1);
  ok -d "./t/.tran/original/git/$cwd/t/git_test/0.1";
  is $res, 1;
  is $version, '0.1';
  is $translation, 'module-pod-jp-articles';
  is slurp("./t/.tran/original/git/$cwd/t/git_test/0.1/README"), "0.1\n", "README contains 0.1";
};

subtest 'get from git 0.2' => sub {
  my $cwd = cwd();
  my ($res, $translation, $version) = $resource->get("file:///$cwd/t/git_test/", 0.2);
  ok -d "./t/.tran/original/git/$cwd/t/git_test/0.2";
  is $res, 1;
  is $version, '0.2';
  is $translation, 'module-pod-jp-articles';
  is slurp("./t/.tran/original/git/$cwd/t/git_test/0.2/README"), "0.2\n", "README contanins 0.2";
};

done_testing;
