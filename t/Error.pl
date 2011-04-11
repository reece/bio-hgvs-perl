#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use FindBin;
use lib "$FindBin::RealBin/../lib";
use Bio::HGVS::Error;

plan tests => 6;

my $e;

$e = Bio::HGVS::Error->new( 'error text' );
is( $e->error, 'error text', 'Error->new(1 arg) construction' );
like( $e, '/^! Bio::HGVS::Error occurred/', 'Error->new(1 arg) stringification' );

$e = Bio::HGVS::Error->new( 'error', 'detail', 'advice' );
is( $e->error,  'error',  'Error->new(3 args) error'  );
is( $e->detail, 'detail', 'Error->new(3 args) detail' );
is( $e->advice, 'advice', 'Error->new(3 args) advice' );
like( $e, '/^! Bio::HGVS::Error occurred.+^Detail:.+^Advice.+^Trace/ms', 'Error->new(3 args) stringification' );


