package Tran::Repository::Translation::ModulePodJpModules::VCS;

use strict;
use warnings;
use base qw/Tran::VCS::Git/;

sub checkout_target {
  my ($self, $target_path, $version) = @_;
  $self->_method
    (sub {
       my $git = shift;
       $target_path .= '-Doc-JA';
       my $module = $self->relative_path($target_path);
       my $uri = "git://github.com/module-pod-jp.git";
       $self->{plus_path} = $module;
       local $@;
       eval {
         $git->clone($uri);
       };
       return $@ ? 0 : 1;
     });
}

1;
