#!/usr/bin/env perl
use Test::Most;

BEGIN { use_ok('DBIx::Query') }
diag( "Testing DBIx::Query $DBIx::Query::VERSION, Perl $], $^X" );
done_testing();
