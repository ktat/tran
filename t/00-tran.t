BEGIN { $ENV{HOME} = './t/'; }
use Test::More;
use Test::Pretty;
use lib qw(lib t/lib);
use Tran;
use Tran::Util -string;
use strict;

my @translation_repos  = qw/Jpa JprpCore JprpModules ModulePodJpModules/;
my @original_resources = qw/Cpan Git Website/;
my @original_repos     = 'directory';
ok(my $tran = Tran->new("t/_tran/config.yml"));

is(ref $tran->original_repository, 'Tran::Repository::Original');
is(ref $tran->log, 'Tran::Log::Null');
is($tran->encoding, 'utf8');

foreach my $r (qw/Cpan/) {
  is(ref $tran->resource($r), 'Tran::Resource::' . $r);
}
is_deeply([sort keys %{$tran->resources}], [sort @original_resources]);
is_deeply(ref $tran->original, 'Tran::Repository::Original');
foreach my $t (@translation_repos) {
  is(ref $tran->translation_repository->{decamelize($t)}, 'Tran::Repository::Translation::' . $t);
}

subtest config =>
  sub {
    my $config = $tran->config;
    is_deeply($config->profile, {name => 'Kato Atsushi', email => 'ktat at example.jp'});
    is($config->default_resource, 'cpan');
    is($config->{file}, 't/_tran/config.yml');
    is_deeply([sort keys %{$config->translation_repository}], [map decamelize($_), @translation_repos]);
    is_deeply([sort keys %{$config->original_repository}], [map decamelize($_), @original_repos]);
    is_deeply([sort keys %{$config->resources}], [map decamelize($_), @original_resources]);
  };

done_testing;
