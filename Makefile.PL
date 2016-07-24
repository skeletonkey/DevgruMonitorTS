use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Devgru::Monitor::TS',
    AUTHOR           => q{Erik Tank <tank@jundy.com>},
    VERSION_FROM     => 'lib/Devgru/Monitor/TS.pm',
    ABSTRACT_FROM    => 'lib/Devgru/Monitor/TS.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::Deep'         => 0,
        'Test::Exception'    => 0,
        'Test::Mock::Simple' => 0,
        'Test::More'         => 0,
    },
    PREREQ_PM => {
        'Carp'            => 0,
        'Devgru::Monitor' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Devgru-Monitor-TS-*' },
);
