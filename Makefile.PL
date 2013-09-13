use inc::Module::Install;

name     'Tran';
all_from 'lib/Tran.pm';
author   q{Ktat <ktat@cpan.org>};
license  'perl';

build_requires 'Test::More' => 0.88;
requires
    'Module::Build'          => 0,
    'App::Cmd'               => 0,
    'Archive::Tar'	     => 0,
    'Class::Inspector'       => 0,
    'Clone'		     => 0,
    'Cwd'		     => 0,
    'FindBin'                => 0,
    'File::Copy'	     => 0,
    'File::Find'	     => 0,
    'File::Path'	     => 0,
    'File::Slurp'	     => 0,
    'IO::Prompt'	     => 0,
    'IO::String'	     => 0,
    'IO::Uncompress::Gunzip' => 0,
    'IO::Uncompress::Bunzip2'=> 0,
    'LWP::Simple'	     => 0,
    'Module::Pluggable'	     => 0,
    'Storable'               => 0,
    'Text::Diff3'	     => 0,
    'Util::Any'		     => '0.17',
    'YAML::XS'               => 0,
    'version'                => 0,
    'Data::Visitor'          => 0,
    'Text::Diff'             => 0,
    'MetaCPAN::API'          => 0,
    ;

recommends
    'Git::Class'             => 0,
    'Cvs::Simple'            => 0,
    'Net::Twitter'           => 0,
    'Email::MIME'            => 0,
    'Email::Sender::Simple'  => 0,
    ;
    
install_script 'script/tran';
# auto_bundle;
WriteAll;
