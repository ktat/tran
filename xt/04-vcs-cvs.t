BEGIN { $ENV{HOME} = './t/'; }
use Test::More;
use lib qw(lib t/lib);
use Tran;
use Tran::Util -string;
use strict;
use File::Path qw/make_path/;
use Cwd qw/cwd/;
use Tran::Util -os;

if (not like_unix()) {
  plan 'skip_all', "test can be run on OS like Unix.";
  exit 1;
}

my $tran = Tran->new("t/_tran/config.yml");
my $tran_vcs = Tran::VCS::CVS->new(
			       wd => "t/.tran/cvs_test/",
			      );

$ENV{CVSROOT} = cwd() . '/t/.tran/cvs_test_repository/';

system(q{
test -e t/.tran/cvs_test_repository/ && rm -rf t/.tran/cvs_test_repository/;
test -e t/.tran/cvs_test             && rm -rf t/.tran/cvs_test;
mkdir t/.tran/cvs_test_repository/ || exit 1;
cd    t/.tran/cvs_test_repository/ || exit 1;
cvs init || exit 1;
cd -;
mkdir t/.tran/cvs_test/ || exit 1;
cd    t/.tran/cvs_test/ || exit 1;
cvs checkout . > /dev/null 2>&1;
echo "Hello" > test.txt || exit 1;
}) == 0 or die "failed initial commands.";

$tran_vcs->add_files();
$tran_vcs->commit();

ok system('cvs status t/.tran/cvs_test/test.txt') == 0;

done_testing;
