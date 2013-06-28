#!/usr/bin/env perl -T
use Test::More tests => 1;

BEGIN {
    use_ok( 'DBIx::Query' ) || print "Bail out!\n";
}

diag( "Testing DBIx::Query $DBIx::Query::VERSION, Perl $], $^X" );
