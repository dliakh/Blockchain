#!/usr/bin/env perl
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Blockchain',
    VERSION_FROM => 'lib/Blockchain.pm',
    PREREQ_PM => {
        Moose => 0,
        LWP => 0,
        URI => 0,
        JSON => 0,
        'URI::Encode' => 0
    }
);