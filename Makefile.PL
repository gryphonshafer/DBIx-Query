#!/usr/bin/env perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'             => 'DBIx::Query',
    'AUTHOR'           => 'Gryphon Shafer <gryphon@cpan.org>',
    'VERSION_FROM'     => 'lib/DBIx/Query.pm',
    'ABSTRACT_FROM'    => 'lib/DBIx/Query.pm',
    'PL_FILES'         => {},
    'MIN_PERL_VERSION' => '5.010',
    'PREREQ_PM'        => {
        'Carp'                    => 0,
        'Clone'                   => 0,
        'DBD::SQLite'             => 0,
        'DBI'                     => 0,
        'SQL::Abstract::Complete' => 1.03,
        'SQL::Parser'             => 0,
        'Test::Most'              => 0,
    },
    'dist'  => { 'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz' },
    'clean' => { 'FILES'    => 'DBIx-Query-*' },
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002 ? ( 'LICENSE' => 'perl' ) : () ),
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( 'META_MERGE' => {
        'meta-spec' => { version => 2 },
        'resources' => {
            'repository' => {
                'type' => 'git',
                'url'  => 'https://github.com/gryphonshafer/DBIx/Query.git',
                'web'  => 'https://github.com/gryphonshafer/DBIx/Query',
            },
        } } ) : ()
    ),
);
