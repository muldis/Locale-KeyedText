#!perl
use 5.008001; use utf8; use strict; use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME' => 'Locale::KeyedText',
	'VERSION_FROM' => 'lib/Locale/KeyedText.pm', # finds $VERSION
	'PREREQ_PM' => {
		'Test::More' => '0.47', # but only for the test suite
	},
);

1;