BEGIN { $ENV{HOME} = './t/'; }
use Test::More;
use lib qw(lib t/lib);
use Tran;
use Tran::Util -string;
use strict;

my @translation_repos  = qw/Jpa JprpCore JprpModules ModulePodJpModules/;
my @original_resources = 'Cpan';
my @original_repos     = 'directory';
ok(my $tran = Tran->new("t/.tran/config.yml"));

is(ref $tran->original_repository, 'Tran::Repository::Original');
is(ref $tran->log, 'Tran::Log::Null');
is($tran->encoding, 'utf8');

foreach my $r (qw/Cpan/) {
  is(ref $tran->resource($r), 'Tran::Resource::' . $r);
}
is_deeply([sort keys %{$tran->resources}], [@original_resources]);
is_deeply(ref $tran->original, 'Tran::Repository::Original');
foreach my $t (@translation_repos) {
  is(ref $tran->translation_repository->{decamelize($t)}, 'Tran::Repository::Translation::' . $t);
}

subtest config =>
  sub {
    my $config = $tran->config;
    is_deeply($config->profile, {name => 'Kato Atsushi', email => 'ktat at example.jp'});
    is($config->default_resource, 'cpan');
    is($config->{file}, 't/.tran/config.yml');
    is_deeply([sort keys %{$config->translation_repository}], [map decamelize($_), @translation_repos]);
    is_deeply([sort keys %{$config->original_repository}], [map decamelize($_), @original_repos]);
    is_deeply([sort keys %{$config->resources}], [map decamelize($_), @original_resources]);
  };

subtest resource =>
  sub {
    my $cpan = $tran->resource('Cpan');
    is $cpan->config->{metafile}, './t/.cpan/Metadata';
    my ($file, $version) = $cpan->get_module_info('ExportTo');
    is($version, '0.03');
    is($file, 'K/KT/KTAT/ExportTo-0.03.tar.gz');
    ($file, $version) = $cpan->get_module_info('ExportTo', '0.01');
    is($version, '0.01');
    is($file, 'K/KT/KTAT/ExportTo-0.01.tar.gz');
    is(ref $cpan->original_repository, 'Tran::Repository::Original');
    is_deeply([sort keys %{$cpan->targets}], ['Moose', 'MooseX::Getopt', 'perl']);
    is($cpan->target_translation('Moose'), 'jpa');
    is($cpan->target_translation('MooseX::Getopt'), 'jpa');
    is($cpan->target_translation('perl'), 'jprp-core');
    $cpan->get('ExportTo', '0.03');
    ok(-e './t/.tran/original/cpan/ExportTo/0.03');
  };

subtest original_repo =>
  sub {
    my $o = $tran->original_repository;
    is($o->resource, 'Cpan');
    ok($o->has_target('TranTest'));
    ok(! $o->has_target('TranTestDummy'));
    is($o->resource_directory, './t/.tran/original/cpan/');
    is($o->directory, './t/.tran/original/');
    is($o->path_of('TranTest'), "./t/.tran/original/cpan/TranTest");
    is($o->path_of('TranTest', '0.01'), "./t/.tran/original/cpan/TranTest/0.01");
    is($o->path_of('TranTest', '0.02'), "./t/.tran/original/cpan/TranTest/0.02");
    is($o->target_path('TranTest', '0.02'), "cpan/TranTest");
    is_deeply($o->get_versions('TranTest'), [0.01, 0.02]);
  };

done_testing;
