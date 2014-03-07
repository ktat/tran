package _testing_;

use Moose;
use Test::More tests => 1;
use lib qw(./lib);

BEGIN {
    use_ok( 'Tran' );
}

diag( "Testing Tran $Tran::VERSION, Perl $], $^X" );

use File::Path qw/rmtree make_path/;
rmtree('t/.tran/original');
make_path('t/.tran/original');

