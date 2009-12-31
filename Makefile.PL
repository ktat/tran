use inc::Module::Install;

name     'Tran';
all_from 'lib/Tran.pm';
author   q{Ktat <ktat@cpan.org>};
license  'perl';

build_requires 'Test::More';
requires
    'Util::Any'		     => '0.17',
    'File::Slurp'	     => 0,
    'File::Find'	     => 0,
    'Text::Diff3'	     => 0,
    'Cwd'		     => 0,
    'LWP::Simple'	     => 0,
    'Module::Pluggable'	     => 0,
    'Clone'		     => 0,
    'IO::String'	     => 0,
    'IO::Uncompress::Gunzip' => 0,
    'File::Path'	     => 0,
    'Archive::Tar'	     => 0,
    'IO::Prompt'	     => 0,
    'File::Copy'	     => 0,
    'App::Cmd'               => 0,
    'version'                => 0,
    'Storable'               => 0,
    ;
    
install_script 'script/tran';
auto_install;

WriteAll;

