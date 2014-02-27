package _testing_;

use Moose;
use Test::More tests => 1;

BEGIN {
    use_ok( 'Tran' );
}

diag( "Testing Tran $Tran::VERSION, Perl $], $^X" );

use File::Path;
rmtree('t/.tran/original');

