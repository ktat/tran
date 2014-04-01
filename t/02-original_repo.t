BEGIN { $ENV{HOME} = './t/'; }
use Test::More;
use lib qw(lib t/lib);
use Tran;
use Tran::Util -string;
use strict;
use File::Path qw/make_path/;

my @translation_repos  = qw/Jpa JprpCore JprpModules ModulePodJpModules/;
my @original_resources = 'Cpan';
my @original_repos     = 'directory';
ok(my $tran = Tran->new("t/_tran/config.yml"));

subtest original_repo => sub {
  my $o = $tran->original_repository;
  is($o->resource('Cpan'), 'Cpan');
  is($o->resource, 'Cpan', 'resource is Cpan');

  is($o->directory, './t/.tran/original/');
  is($o->resource_directory, './t/.tran/original/cpan/');

  make_path('./t/.tran/original/cpan/TranTest/0.01');
  make_path('./t/.tran/original/cpan/TranTest/0.02');

  is($o->target_path('TranTest'), 'TranTest');
  ok($o->has_target('TranTest'));

  ok(! $o->has_target('TranTestDummy'));

  is($o->resource_directory, './t/.tran/original/cpan/');
  is($o->directory, './t/.tran/original/');
  is($o->path_of('TranTest'), "./t/.tran/original/cpan/TranTest");
  is($o->path_of('TranTest', '0.01'), "./t/.tran/original/cpan/TranTest/0.01");
  is($o->path_of('TranTest', '0.02'), "./t/.tran/original/cpan/TranTest/0.02");
  is($o->target_path('TranTest', '0.02'), "TranTest");
  is_deeply($o->get_versions('TranTest'), [0.01, 0.02]);
};

done_testing;
