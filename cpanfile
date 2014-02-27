requires 'App::Cmd';
requires 'Archive::Tar';
requires 'Class::Inspector';
requires 'Clone';
requires 'Data::Util';
requires 'Data::Visitor';
requires 'File::Copy';
requires 'File::Find';
requires 'File::Path';
requires 'File::Slurp';
requires 'FindBin';
requires 'Furl';
requires 'IO::Prompt';
requires 'IO::String';
requires 'IO::Uncompress::Bunzip2';
requires 'IO::Uncompress::Gunzip';
requires 'JSON::XS';
requires 'LWP::Simple';
requires 'MetaCPAN::API';
requires 'Module::Build', '3.07';
requires 'Module::CoreList', '>= 3.07';
requires 'Module::Pluggable';
requires 'Storable';
requires 'Text::Diff';
requires 'Text::Diff3';
requires 'Time::Piece';
requires 'Util::Any', '0.17';
requires 'Web::Query';
requires 'YAML::XS';
recommends 'Cvs::Simple';
recommends 'Email::MIME';
recommends 'Email::Sender::Simple';
recommends 'Git::Class';
recommends 'Net::Twitter';

on build => sub {
    requires 'ExtUtils::MakeMaker', '6.36';
    requires 'Test::More', '0.88';
};
