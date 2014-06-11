BEGIN { $ENV{HOME} = './t/'; }
use Test::More;
use lib qw(lib t/lib);
use Tran;
use Tran::Util -string, -os;
use File::Path qw/remove_tree/;
use strict;
use File::Path qw/make_path/;

if (not like_unix()) {
  plan 'skip_all', "test can be run on OS like Unix.";
  exit 1;
}

foreach my $dir (qw(t/git_test t/git_clone)) {
  if (-d $dir) {
    remove_tree $dir;
  }
  mkdir $dir or die "cannot mkdir $dir";
}

my $tran = Tran->new("t/_tran/config.yml");

my $result = system(<<'_SHELL_');
(
cd t/git_test/              || exit 1;
git init --bare             || exit 1;
cd -                        || exit 1;
git clone file:///$(pwd)/t/git_test t/git_clone || exit 1;
cd t/git_clone || exit 1;
git config user.email 'test@exapmle.com'
git config user.name  'test'
cd - || exit 1;
touch t/git_clone/test.txt || exit 1;
)
_SHELL_

is $result, 0, "prepare git repository";

if ($result) {
  plan 'skip_all', "cannot prepare git repository";
  exit 1;
}

my $vcs = Tran::VCS::Git->new(
			      wd => 't/git_clone/',
			     );
$vcs->add_files();
$vcs->commit();

done_testing;
