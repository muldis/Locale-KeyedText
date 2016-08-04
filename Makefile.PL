use 5.008001;
use utf8;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME' => 'Locale::KeyedText',
    'VERSION' => '1.73.0',
    'ABSTRACT' => 'Refer to user messages in programs by keys',
    'AUTHOR' => 'Darren Duncan <darren@DarrenDuncan.net>',
#    'LICENSE' => 'lgpl_3_0',
    'PREREQ_PM' => {
        # These mainly add features to Perl 5 that are built-in to Perl 6.
        'Readonly' => 1.03,
        'Class::Std' => 0.000008,
        'Class::Std::Utils' => 0.000002,
        'Scalar::Util' => 0,
        # These are used in both the Perl 5 and Perl 6 versions.
        #   (None yet, if ever.)
        # These mainly are for the test suite.
        'Test::More' => 0,
    },
);

1; # Magic true value required at end of a reusable file's code.
