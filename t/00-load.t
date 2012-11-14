#!perl -T
use 5.008001;
use strict;
use warnings FATAL => 'all';
use Test::Base;

plan tests => 1;

BEGIN {
    use_ok( 'YAML::Loaf' ) || print "Bail out!\n";
}

diag( "Testing YAML::Loaf $YAML::Loaf::VERSION, Perl $], $^X" );

