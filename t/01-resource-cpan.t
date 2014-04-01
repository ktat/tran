use Test::More;
use strict;
use lib qw(lib t/lib);
use File::Path qw/remove_tree/;

use Tran;

if (-d "./t/.tran/original/cpan/") {
  remove_tree './t/.tran/original/cpan/';
}

my $tran = Tran->new('./t/_tran/config.yml');

my %resource;
my $cpan    = $tran->resource('Cpan');

ok $cpan, 'cpan';

subtest 'get bundled module' => sub {
  my ($pod, $version) = $cpan->get_module_info_from_metacpan_with_corelist('File::Spec');
  ok($pod =~ m{=head1 NAME\n+File::Spec}s, 'File::Spec pod');
  ok($version, "version is $version");
};

subtest 'get core document' => sub {
  my ($pod, $version) = $cpan->get_core_document_from_metacpan('perlootut');
  like($pod, qr{=head1 NAME\n+perlootut}s, 'perlootut pod');
  ok($version, "version is $version");
};

subtest 'get module' => sub {
  my $cpan = $tran->resource('Cpan');
  my ($file, $version) = $cpan->get_module_info_from_metacpan('ExportTo');
  is($version, '0.03');
  is($file, 'http://cpan.metacpan.org/authors/id/K/KT/KTAT/ExportTo-0.03.tar.gz');
  $cpan->get('ExportTo', '0.03');
  ok(-e './t/.tran/original/cpan/ExportTo/0.03');
};

subtest 'get module with version' => sub {
  my($file, $version) = $cpan->get_module_info_from_metacpan('ExportTo', '0.01');
  is($version, '0.01');
  is($file, 'http://cpan.metacpan.org/authors/id/K/KT/KTAT/ExportTo-0.01.tar.gz');
};

subtest 'resource cpan' => sub {
  is(ref $cpan->original_repository, 'Tran::Repository::Original');
  is_deeply([sort keys %{$cpan->targets}], ['Moose', 'MooseX::Getopt', 'perl']);
  is($cpan->target_translation('Moose'), 'jpa');
  is($cpan->target_translation('MooseX::Getopt'), 'jpa');
  is($cpan->target_translation('perl'), 'jprp-core');
};

done_testing;

