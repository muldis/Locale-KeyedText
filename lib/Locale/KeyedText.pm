use 5.008000;
use utf8;
use strict;
use warnings;

use Locale::KeyedText::Message 2.001001;
use Locale::KeyedText::Translator 2.001001;

{ package Locale::KeyedText; # package
    BEGIN {
        our $VERSION = '2.001001';
        $VERSION = eval $VERSION;
    }
} # package Locale::KeyedText

1;
