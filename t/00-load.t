#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Tran' );
}

diag( "Testing Tran $Tran::VERSION, Perl $], $^X" );
