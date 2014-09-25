# DBIx::Query - Simplified abstracted chained DBI subclass

This module provides a simplified abstracted chained DBI subclass. It's sort of
like jQuery for DBI, or sort of like DBIx::Class only without objects, or sort
of like cookies without a glass of milk.

[![Build Status](https://travis-ci.org/gryphonshafer/DBIx-Query.svg)](https://travis-ci.org/gryphonshafer/DBIx-Query)
[![Coverage Status](https://coveralls.io/repos/gryphonshafer/DBIx-Query/badge.png)](https://coveralls.io/r/gryphonshafer/DBIx-Query)

With DBIx::Query, you can construct queries either with SQL or abstract Perl
data structures described by SQL::Abstract::Complete.

    my $stuff  = $dq->sql('SELECT stuff FROM things WHERE value = ?')->run(42)->all();
    my $things = $dq->get( 'things', ['stuff'], { 'value' = 42 } )->run()->all();

The overall point being that you can chain various parts of the query prepare,
execute, and data retrieval process to dramatically reduce repeated code in
most programs.

    my $c_value    = $dq->sql('SELECT a FROM b WHERE c = ?')->run($c)->value();
    my $everything = $dq->get('things')->run()->all({});

DBIx::Query is a pure subclass of DBI, so it can be used exactly like DBI. At
any point, you can drop out of DBIx::Query-specific methods and use DBI methods.

    my $sth = $dq->get('things');
    $sth->execute();
    my $stuff = $sth->fetchall_arrayref();

Like DBI, there are multiple sub-classes each with a set of methods related
to its level. In DBI, there is: DBI (the parent class), db (the object
created from a connect call), and st (the statement handle). DBIx::Query adds
the following additional: rowset, row, and cell.

## Installation

To install this module, run the following commands:

    perl Makefile.PL
    make
    make test
    make install

## Support and Documentation

After installing, you can find documentation for this module with the
perldoc command.

    perldoc DBIx::Query

You can also look for information at:

- [GitHub](https://github.com/gryphonshafer/DBIx-Query "GitHub")
- [AnnoCPAN](http://annocpan.org/dist/DBIx-Query "AnnoCPAN")
- [CPAN Ratings](http://cpanratings.perl.org/m/DBIx-Query "CPAN Ratings")
- [Search CPAN](http://search.cpan.org/dist/DBIx-Query "Search CPAN")

## Author and License

Gryphon Shafer, [gryphon@cpan.org](mailto:gryphon@cpan.org "Email Gryphon Shafer")

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
