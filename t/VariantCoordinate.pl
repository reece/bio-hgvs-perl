#!/usr/bin/perl

use Test::Simple tests => 3;

use lib '../../..';
use Bio::HGVS::VariantCoordinate;

my $c;


$c = Bio::HGVS::VariantCoordinate->new(
  start => 12,
  end => 34,
);

ok( "$c" eq "12_34" );



$c = Bio::HGVS::VariantCoordinate->new(
  start => 12,
  offset => 6,
);
ok( "$c" eq "12+6" );


$c = Bio::HGVS::VariantCoordinate->new(
  start => 12,
  offset => -8,
);
ok( "$c" eq "12-8" );


#$c = Bio::HGVS::VariantCoordinate->new(
#  start => 12,
#  end => 34,
#  offset => 6,
#);
#ok( "$c" eq "12_34" );
