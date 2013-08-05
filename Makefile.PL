use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'DBIx::Query',
    AUTHOR           => q{Gryphon Shafer <gryphon@cpan.org>},
    VERSION_FROM     => 'lib/DBIx/Query.pm',
    ABSTRACT_FROM    => 'lib/DBIx/Query.pm',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.10.1',
    PREREQ_PM        => {
        'Test::More'              => 0,
        'SQL::Abstract::Complete' => 1.03,
        'DBI'                     => 0,
        'DBD::SQLite'             => 0,
        'SQL::Parser'             => 0,
        'Carp'                    => 0,
        'Clone'                   => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'DBIx-Query-*' },
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE'=> 'perl') : () ),
);



