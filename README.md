# NAME

DBIx::Query - Simplified abstracted chained DBI subclass

# VERSION

version 1.13

[![test](https://github.com/gryphonshafer/DBIx-Query/workflows/test/badge.svg)](https://github.com/gryphonshafer/DBIx-Query/actions?query=workflow%3Atest)
[![codecov](https://codecov.io/gh/gryphonshafer/DBIx-Query/graph/badge.svg)](https://codecov.io/gh/gryphonshafer/DBIx-Query)

# SYNOPSIS

    use DBIx::Query;

    my $dq = DBIx::Query->connect(
        "dbi:Pg:dbname=$db_name;host=$db_host",
        $user,
        $pwd,
        { dq_dialect => 'ANSI' },
    );

    # get stuff, things, and everything easily
    my $everything = $dq->get('things')->run->all({});
    my $things     = $dq->get( 'things', ['stuff'], { 'value' => 42 } )->run->all;
    my $stuff      = $dq->sql('SELECT stuff FROM things WHERE value = ?')->run(42)->all;

    # can use DBI methods at any point
    my $sth = $dq->get('things');
    $sth->execute;
    $stuff = $sth->fetchall_arrayref;

    # get all from data where a is 42 (as an arrayref of hashrefs)
    my $data = $dq->get('data')->where( 'a' => 42 )->run->all({});

    my $row_set = $dq->sql('SELECT a, b FROM data WHERE x = ?')->run(42);
    my $row_0   = $row_set->next;
    my $a_value = $row_0->cell('a')->value;

    use Data::Dumper 'Dumper';
    $dq->sql('SELECT a, b, c FROM data')->run->each( sub {
        my ($row) = @_;
        print Dumper( $row->data ), "\n";
    } );

    my $row = $dq->sql('SELECT id, name FROM data')->run->next;

    $row->cell( 'name', 'New Value' )->up->save('id');
    $row->save( 'id', { 'name' => 'New Value' } );
    $row->save( 'id', { 'name' => 'New Value' }, 0 );

    $dq->add( 'user', { 'id' => 'thx1138' } );
    $dq->update( 'user', { 'id' => 'thx1138' }, { 'id' => 'lv427' }, 0 );
    $dq->rm( 'user', { 'id' => 'thx1138' } );

# DESCRIPTION

This module provides a simplified abstracted chained DBI subclass. It's sort of
like jQuery for [DBI](https://metacpan.org/pod/DBI), or sort of like DBIx::Class only without objects, or sort
of like cookies without a glass of milk. With DBIx::Query, you can construct
queries either with SQL or abstract Perl data structures described by
[SQL::Abstract::Complete](https://metacpan.org/pod/SQL%3A%3AAbstract%3A%3AComplete).

    my $stuff  = $dq->sql('SELECT stuff FROM things WHERE value = ?')->run(42)->all;
    my $things = $dq->get( 'things', ['stuff'], { 'value' = 42 } )->run->all;

The overall point being that you can chain various parts of the query prepare,
execute, and data retrieval process to dramatically reduce repeated code in
most programs.

    my $c_value    = $dq->sql('SELECT a FROM b WHERE c = ?')->run($c)->value;
    my $everything = $dq->get('things')->run->all({});

DBIx::Query is a pure subclass of DBI, so it can be used exactly like DBI. At
any point, you can drop out of DBIx::Query-specific methods and use DBI methods.

    my $sth = $dq->get('things');
    $sth->execute;
    my $stuff = $sth->fetchall_arrayref;

Like [DBI](https://metacpan.org/pod/DBI), there are multiple sub-classes each with a set of methods related
to its level. In [DBI](https://metacpan.org/pod/DBI), there is:

- DBI (the parent class)
- db (the object created from a connect call)
- st (the statement handle)

DBIx::Query adds the following additional:

- rowset
- row
- cell

# PARENT CLASS METHODS

The following methods exists at the "parent class" level.

## connect

This method is mostly inherritted from [DBI](https://metacpan.org/pod/DBI)'s `connect_cached()`. Since
DBIx::Query is a true subclass of [DBI](https://metacpan.org/pod/DBI), typically the only thing you have to
do to switch from [DBI](https://metacpan.org/pod/DBI) to DBIx::Query is to change the `connect()` method's
package name.

    my $dq = DBIx::Query->connect(
        "dbi:Pg:dbname=$db_name;host=$db_host", $username, $password,
    );

The object returned is a database object and so will support both [DBI](https://metacpan.org/pod/DBI) and
DBIx::Query methods associated with database objects.

There are some caveats. First, the default behavior of DBIx::Query's
`connect()` is actually DBI's `connect_cached`. If you want a non-cached
connect, look at `connect_uncached()` below. Second, the default attributes
of the connection will have "RaiseError" on and "PrintError" off. These can be
easily overridden if you desire.

### dq\_dialect

As part of the optional attribute hashref for `connect()`, you may pass in an
optional `dq_dialect` value. This should be a string that represents the SQL
dialect you're going to use, and for which DBIx::Query should be prepared to
parse.

    my $dq = DBIx::Query->connect(
        'dbi:SQLite:dbname=:memory:',
        undef,
        undef,
        { dq_dialect => 'ANSI' },
    );

For more information, see [SQL::Parser](https://metacpan.org/pod/SQL%3A%3AParser) documentation on dialect. If not
specified, DBIx::Query defaults to the "ANSI" dialect.

## connect\_uncached

If you'd prefer [DBI](https://metacpan.org/pod/DBI)'s normal, uncached `connect()` behavior, you can use
`connect_uncached()`.

## errstr

This method is inherritted from [DBI](https://metacpan.org/pod/DBI).

# DATABASE CLASS PRIMARY METHODS

The following methods are "primary" methods of the database class, the object
returned from a `connect()` call. "Primary" in this case means common use
methods you'll probably want to know about.

## connection

Once you have established a connection, you can retrieve information about that
connection using this method. It expects either no input or a list of strings
that consist of: dsn, user, pass, attr. If a string is provided, the value is
returned.

    my $dsn = $dq->connection('dsn');

If multiple strings are provided, values for those are returned either as an
arrayref or array depending on context.

    my $arrayref = $dq->connection( qw( dsn user ) );
    my @array    = $dq->connection( qw( dsn user ) );

If no values are provided, this method returns a hashref or an array of values
depending on the context.

    my $hashref = $dq->connection;
    my @array   = $dq->connection;

## sql

This method accepts SQL and optional attributes, cache type definition, and
variables and returns a DBIx::Query statement handle.

    my $sth = $db->sql('SELECT alpha, beta, COUNT(*) FROM things WHERE delta > ?');

The method must be passed SQL as its first input, then it can accept optional
inputs in the order: attributes hashref, cache type integer, and variables
arrayref.

    my $sth = $db->sql(
        'SELECT alpha, beta, COUNT(*) FROM things WHERE delta > ?',
        {},
        3,
        [42],
    );

If the cache type definition is `undef`, then DBIx::Query will set it to 3.
(See [DBI](https://metacpan.org/pod/DBI) for details of what the 1, 2, and 3 level caching means.) If you'd
prefer no caching, you can set cache type to -1 or use `sql_uncached`.

The attributes value is passed through to the `prepare()` or
`prepare_cached()` call. The values (if any are provided) are stored in the
statement handle and used as default values if none are provided later during
`run()`.

## sql\_uncached

This method is the equivalent of `sql()` with the cache value set to -1, which
results in a normal `prepare` call instead of `prepare_cached`.

## get

The second way to build a statement handle is through the use of `get()`,
which expects some number of input parameters that are fed into
[SQL::Abstract::Complete](https://metacpan.org/pod/SQL%3A%3AAbstract%3A%3AComplete) to generate SQL.

    my $sth = $dq->get(
        $table || \@tables, # a table or set of tables and optional aliases
        \@columns,          # fields and optional aliases to fetch
        \%where,            # where clause
        \%other,            # order by, group by, having, and pagination
        \%attr,             # attributes
        $cache_type,        # cache type
    );

The first 4 inputs are passed directly to [SQL::Abstract::Complete](https://metacpan.org/pod/SQL%3A%3AAbstract%3A%3AComplete), so
consult that documentation for details. The last 2 inputs are the same as what
is used for `sql()`.

If the cache type definition is `undef`, then DBIx::Query will set it to 3.
(See [DBI](https://metacpan.org/pod/DBI) for details of what the 1, 2, and 3 level caching means.) If you'd
prefer no caching, you can set cache type to -1 or use `sql_uncached`.

## get\_uncached

This method is the equivalent of `get()` with the cache value set to -1, which
results in a normal `prepare` call instead of `prepare_cached`.

## add

Inserts a row into the database and returns the primary key for that row if
available.

    my $pk0 = $dq->add( $table_name, $params, $attr, $cache_type );
    my $pk1 = $dq->add( 'user', { 'id' => 'thx1138' } );

The `$params` value is either an arrayref or hashref of fields and values for
the insert. The `$attr` value is any attribute set that would get passed to
[DBI](https://metacpan.org/pod/DBI)'s `last_insert_id()` to obtain the primary key. If the cache type
definition is `undef`, then DBIx::Query calls [DBI](https://metacpan.org/pod/DBI)'s `prepare()`, else it
calls `prepare_cached()` and uses the cache type as the `$if_active`.
(See the [DBI](https://metacpan.org/pod/DBI) documentation.)

## rm

Deletes a row from the database and returns the object from which the method
was called.

    my $dq0 = $dq->rm( $table_name, $params, $attr, $cache_type );
    my $dq1 = $dq->rm( 'user', { 'id' => 'thx1138' } );

The `$params` value is a hashref of fields and values for the delete. If the
cache type definition is `undef`, then DBIx::Query calls [DBI](https://metacpan.org/pod/DBI)'s `prepare()`,
else it calls `prepare_cached()` and uses the cache type as the `$if_active`.
(See the [DBI](https://metacpan.org/pod/DBI) documentation.)

## update

Updates a row in the database and returns the object from which the method
was called.

    my $dq0 = $dq->update( $table_name, $params, $where, $attr, $cache_type );
    my $dq1 = $dq->update(
        'user',
        { 'id' => 'thx1138' },
        { 'id' => 'lv427' },
        0,
    );

The `$params` value is a hashref of fields and values for the update. The
`$where` value is a hashref of fields and values to be used as a where clause
for the update.

If the cache type definition is `undef`, then DBIx::Query will set it to 3.
(See [DBI](https://metacpan.org/pod/DBI) for details of what the 1, 2, and 3 level caching means.) If you'd
prefer no caching, you can set cache type to -1 or use `sql_uncached`.

# DATABASE CLASS HELPER METHODS

The following methods are "helper" methods of the database class, the object
returned from a `connect()` call.

## get\_run

Takes the same parameters as `get`. It internally calls `get()` followed
by `execute()`, then returns the executed statement handle.

    my @movie_titles_page = $dq->get_run(
        'movie',
        ['title'],
        undef,
        {
            'group_by' => 'title',
            'having'   => [ { 'MAX(sales)' => { '>' => 9 } } ],
            'order_by' => [ 'title', { '-desc' => 'budget' }, 'studio' ],
            'rows'     => 5,
            'page'     => 3,
        },
    )->column;

## fetch\_value

Takes the same parameters as `get`. It internally calls `get_run()` and
returns the first row, first column value.

    my $highest_grossing_movie_title = $dq->fetch_value(
        'movie',
        ['title'],
        undef,
        { 'order_by' => [ { '-desc' => 'budget' }, 'title', studio' ] },
    );

## fetchall\_arrayref

Takes the same parameters as `get`. It internally calls `get_run()` followed
by `execute()`, then returns the results of a `fetchall_arrayref()` on the
executed statement handle.

    my $movies = $dq->fetchall_arrayref( 'movie', [ 'title', 'studio' ] );

## fetchall\_hashref

Basically the same thing as `fetchall_arrayref()` called on the database class
except it returns an array of hashrefs. (It just calls `fetchall_arrayref({})`
on the statement handle.)

    my $movies = $dq->fetchall_hashref( 'movie', [ 'title', 'studio' ] );

## fetch\_column\_arrayref

Takes the same parameters as `get`. It internally calls `fetchall_arrayref()`
against the database class and returns the first column's values as an arrayref.

    my $movie_titles = $dq->fetchall_hashref( 'movie', ['title'] );

## fetchrow\_hashref

Accepts some SQL and other optional values, prepares and executes the query,
and returns the first row as a hashref.

    my $hashref_row = $dq->fetchrow_hashref( $sql, $variables, $attr, $cache_type );

Variables for the query are expected in an arrayref. Attributes are expected as
a hashref. And the cache type is by default set to 3 if not defined. If you want
to skip caching, pass a value of -1.

# STATEMENT HANDLE METHODS

The following methods are available from statement handle objects. These along
with inherritted [DBI](https://metacpan.org/pod/DBI) statement handle methods are available from statement
handle objects returned from a variety of [DBIx::Query](https://metacpan.org/pod/DBIx%3A%3AQuery) methods.

## where

If and only if you use `get()` to construct your statement handle, you can
optionally use `where()` to add or alter the where clause.

    # data where a = 42
    $dq->get('data')->where( 'a' => 42 )->run->all({});

    # data where a = 13 (original where is altered)
    $dq->get( 'data', undef, { 'a' => 42 } )->where( 'a' => 13 )->run->all({});

    # data where a = 42 and b = 13 (original where is appended to)
    $dq->get( 'data', undef, { 'a' => 42 } )->where( 'b' => 13 )->run->all({});

## run

Executes the statement handle. It will execute the handle with whatever
parameters are passed in as variables. If no variables are provided, it will
execute the handle based on variables previously provided. Otherwise, it'll
execute the handle without input. Then `run()` will return a "row set" back.
(See below for more details on row sets.)

    my $row_set_0 = $dq->sql('SELECT a, b FROM data WHERE x = 42')->run;
    my $row_set_1 = $dq->sql('SELECT a, b FROM data WHERE x = ?')->run(42);
    my $row_set_2 = $dq->sql('SELECT a, b FROM data WHERE x = ?', undef, undef, [42] )->run;
    my $row_set_3 = $dq->get( 'data', [ 'a', 'b' ], { 'x' => 42 } )->run;

## sql

Returns a string consisting of the SQL the statement handle has.

## structure

Returns a data structure consisting of the parsed SQL the statement handle has,
if that structure is available. This is fulfilled using [SQL::Parser](https://metacpan.org/pod/SQL%3A%3AParser).
(See `SQL::Parser` for details of the returned data.)

## table

Returns the primary table of the SQL for the statement handle. This is just a
short-cut to:

    $sth->structure->{'table_names'}[0]

## up

When called against a statement handle, returns the database object.

# ROW SET OBJECT METHODS

Row sets are returned from `run()` called on a statement handle. The represent
a group or set of rows the database has or will return.

## next

If you consider that a row set is a container for some number of rows, this
method returns the next row of the set.

    my $row = $db->sql($sql)->run->next;

You can pass an integer into `next()` to tell it to skip a certain number of
rows and return to you the next after that skip.

## all

A simple dumper of data for the given row set. This operates like [DBI](https://metacpan.org/pod/DBI)'s
`fetchall_arrayref()` on an executed statement handle.

    my $arrayref_of_arrayrefs = $db->sql($sql)->run->all;
    my $arrayref_of_hashrefs  = $db->sql($sql)->run->all({});

## each

This is a row iterator that lets you run a block of code against each row in a
row set. After running the code block against each row, the method returns a
reference to the object from which the method was called. The code block will
get passed to it a row object. (See below.)

    use Data::Dumper 'Dumper';
    my $dq0 = $dq->sql('SELECT a, b, c FROM data')->run->each( sub {
        my ($row) = @_;
        print Dumper( $row->data ), "\n";
    } );

## value

This method returns the value (or values) of the first row of a returned data
set. The assumption is that the query is expecting only a single returned row
of data.

    my $value  = $dq->sql('SELECT a FROM data LIMIT 1')->run->value;
    my @values = $dq->sql('SELECT a, b FROM data LIMIT 1')->run->value;

If in scalar context, the method assumes there is only a column returned and
returns that value only. If there are multiple columns but the method is called
in scalar context, the method throws an error. (If there are multiple rows
found, only the first row's data will be returned, and no error will be thrown.)

## first

Returns the first record. Has a similar interface to `all()` in that it'll
normally return an arrayref of data, but if you pass in an empty hashref, it'll
return a hashref of data.

    my $arrayref = $db->sql($sql)->run->first;
    my $hashref  = $db->sql($sql)->run->first({});

If there are more than 1 rows the query will select, only the first row is
returned.

## column

Assuming a query that's going to return a column of data, this method will
return the column of data as a list or an arrayref depending on context.

    my $arrayref = $db->sql($sql)->run->column;
    my @array    = $db->sql($sql)->run->column;

If there are more than 1 columns requested in the query, only the first column
is returned.

## up

When called against a row set object, returns the statement handle.

# ROW OBJECT METHODS

Row objects are returned from row set methods like `next()`. They represent
a single row of returned database data.

## cell

Returns a cell object of the cell requested by index. The index can be
the name of the column (which is usually but not always available) or the
integer index (which is available if columns are specified in the query).

    print $dq->sql('SELECT * FROM data WHERE a = ?')->run(42)->next->cell('b')->value, "\n";
    print $dq->get('data')->run->next->cell('b')->value, "\n";

    # returns column "b" value
    print $dq->sql('SELECT a, b FROM data WHERE a = ?')->run(42)->next->cell(1)->value, "\n";

If columns are not specified in the query and an integer index is used, an
error will be thrown.

    # don't do this...
    eval { $dq->sql('SELECT * FROM data WHERE a = ?')->run(42)->next->cell(1)->value };

Optionally, this method will set the value of the cell (in memory only, not in
the database yet) based on an index and new value.

    print $dq->get('data')->run->next->cell( 'b', 'New Value' )->value, "\n";

## each

Similar to `each()` from the row set object, `each()` on a row object will
execute a subroutine on each cell of the row. The subroutine reference is passed
a cell object.

    $dq->sql('SELECT a, b, c FROM data')->run->next->each( sub {
        my ($cell) = @_;
        print $cell->value, "\n";
    } );

This method will only work if the query in question has some form of columns
defined, either through `sql()` or `get()` with a column reference. Otherwise,
it will throw an error.

## data

Returns the data of the row as a hashref.

    my $hashref = $dq->get('data')->run->next->data;

In some situations with very complex SQL, the SQL parser will fail. In those
cases, `data()` cannot be used. Instead, use `row()`.

## row

Returns the data of the row as an arrayref.

    my $arrayref = $dq->get('data')->run->next->data;

## save

Saves back to the database the row. It requires a scalar or arrayref "key"
representing the primary key or keys (or enough data that a where clause will
know how to find the record in the database).

You can change data for the row using `cell()` before the `save()` call or
within the `save()` call by passing in a second parameter, a hashref of
parameters.

Once the update is complete, the method will return a fresh row object pulled
from the database using the where clause generated based on the key or keys.
The third argument is an optional cache type for the inner SQL execution call.

    my $row = $dq->sql('SELECT id, name FROM data')->run->next;

    $row->cell( 'name', 'New Value' )->up->save('id');
    $row->save( 'id', { 'name' => 'New Value' } );
    $row->save( 'id', { 'name' => 'New Value' }, 0 );

## up

When called against a row object, returns the row set handle.

# CELL OBJECT METHODS

Cell objects are returned by calling `cell()` on a row. They represent a
single cell of returned database data.

## name

Returns the name of the cell.

    my $cell = $dq->sql('SELECT id, name FROM data')->run->next->cell('id');
    $cell->name(); # returns "id"

## value

Returns the value of the cell.

    my $cell = $dq->sql('SELECT id, name FROM data')->run->next->cell('name');
    $cell->value;

## index

Returns the index of the cell.

## save

Saves any changes to the row the cell is part of by calling `save()` on that
row. For example, the last two lines here are identical:

    my $row = $dq->sql('SELECT id, name FROM data')->run->next;

    $row->cell( 'name' => 'New Value' )->up->save('id');
    $row->cell( 'name' => 'New Value' )->save('id');

## up

When called against a cell object, returns the row object to which it belongs.

# SEE ALSO

[SQL::Abstract::Complete](https://metacpan.org/pod/SQL%3A%3AAbstract%3A%3AComplete), [DBI](https://metacpan.org/pod/DBI).

You can also look for additional information at:

- [GitHub](https://github.com/gryphonshafer/DBIx-Query)
- [MetaCPAN](https://metacpan.org/pod/DBIx::Query)
- [GitHub Actions](https://github.com/gryphonshafer/DBIx-Query/actions)
- [Codecov](https://codecov.io/gh/gryphonshafer/DBIx-Query)
- [CPANTS](http://cpants.cpanauthors.org/dist/DBIx-Query)
- [CPAN Testers](http://www.cpantesters.org/distro/D/DBIx-Query.html)

# AUTHOR

Gryphon Shafer <gryphon@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2013-2021 by Gryphon Shafer.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
