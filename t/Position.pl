#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use FindBin;
use lib "$FindBin::RealBin/../lib";
use Bio::HGVS::Position;

plan tests => 51;

# TODO: use hard-coded values with known outcomes

my ($l1,$l2,$l3,$l4);
my $p;
my $position;
my $intron_offset;

# new/easy_new with offset 0
$l1 = Bio::HGVS::Position->new( position => 10 );
isa_ok($l1, 'Bio::HGVS::Position');
is( $l1, '10', 'new(=>10) stringify');
$l2 = Bio::HGVS::Position->new( position => 10, intron_offset => 0 );
isa_ok($l2, 'Bio::HGVS::Position');
is( $l2, '10', 'new(=>10,=>0) stringify');
$l3 = Bio::HGVS::Position->easy_new( 10 );
isa_ok($l3, 'Bio::HGVS::Position');
is( $l3, '10', 'new(10) stringify');
$l4 = Bio::HGVS::Position->easy_new( 10, 0 );
isa_ok($l4, 'Bio::HGVS::Position');
is( $l4, '10', 'new(10,0) stringify');
is( $l1, $l2, 'new(=>10) == new(=>10,=>0)' );
is( $l1, $l3, 'new(=>10) == easy_new(10)' );
is( $l1, $l4, 'new(=>10) == easy_new(10,0)' );
is( $l2, $l3, 'new(=>10,=>0) == easy_new(10)' );
is( $l2, $l4, 'new(=>10,=>0) == easy_new(10,0)' );
is( $l3, $l4, 'easy_new(10) == easy_new(10,0)' );

# new/easy_new with offset +5
$l2 = Bio::HGVS::Position->new( position => 10, intron_offset => 5 );
isa_ok($l2, 'Bio::HGVS::Position');
is( $l2, '10+5', 'new(=>10,=>5) stringify');
$l4 = Bio::HGVS::Position->easy_new( 10, 5 );
isa_ok($l4, 'Bio::HGVS::Position');
is( $l4, '10+5', 'new(10,5) stringify');
is( $l2, $l4, 'new(=>10,=>5) == easy_new(10,5)' );

# new/easy_new with offset -5
$l2 = Bio::HGVS::Position->new( position => 10, intron_offset => -5 );
isa_ok($l2, 'Bio::HGVS::Position');
is( $l2, '10-5', 'new(=>10,=>-5) stringify');
$l4 = Bio::HGVS::Position->easy_new( 10, -5 );
isa_ok($l4, 'Bio::HGVS::Position');
is( $l4, '10-5', 'new(10,-5) stringify');
is( $l2, $l4, 'new(=>10,=>-5) == easy_new(10,-5)' );


# simple position (offset == 0)
$position = int(rand(1000));
$p = Bio::HGVS::Position->new( position => $position );
isa_ok($p, 'Bio::HGVS::Position', 'instance created in correct class');
isa_ok($p, 'Bio::HGVS::Location', 'is a subclass of Bio::HGVS::Location');
is($p->position, $position, "position=$position (random)");
is("$p", "$position", "stringification ($p=$position)");
ok($p->is_simple, 'is_simple');
is($p->len, 1, "length=1");

# non-simple position (offset != 0)
$position = int(rand(1000));
$intron_offset = int(rand(50))-25;
$p = Bio::HGVS::Position->new( position => $position,
							   intron_offset => $intron_offset );
isa_ok($p, 'Bio::HGVS::Position', 'instance created in correct class');
isa_ok($p, 'Bio::HGVS::Location', 'is a subclass of Bio::HGVS::Location');
is($p->position, $position, "position=$position (random)");
like("$p", qr/\Q$position\E.*$intron_offset/, "stringification ($p)");
ok( not($p->is_simple), "isn't simple" );
is($p->len, 1, "length=1");

# non-simple position (offset=0, position=*)
$position = '*'.int(rand(1000));
$p = Bio::HGVS::Position->new( position => $position );
isa_ok($p, 'Bio::HGVS::Position', 'instance created in correct class');
isa_ok($p, 'Bio::HGVS::Location', 'is a subclass of Bio::HGVS::Location');
is($p->position, $position, "position=$position (random)");
is("$p", $position, "stringification ($p)");
ok( not($p->is_simple), "isn't simple" );
is($p->len, 1, "length=1");

# non-simple position (position=* w/offset)
$position = '*'.int(rand(1000));
$intron_offset = int(rand(50))-25;
$p = Bio::HGVS::Position->new( position => $position,
							   intron_offset => $intron_offset );
isa_ok($p, 'Bio::HGVS::Position', 'instance created in correct class');
isa_ok($p, 'Bio::HGVS::Location', 'is a subclass of Bio::HGVS::Location');
is($p->position, $position, "position=$position (random)");
like("$p", qr/\Q$position\E.*$intron_offset/, "stringification ($p)");
ok( not($p->is_simple), "isn't simple" );
is($p->len, 1, "length=1");



$position = int(rand(1000));
$intron_offset = int(rand(50))-25;
my $p1 = Bio::HGVS::Position->new( position => $position,
								   intron_offset => $intron_offset );
my $p2 = Bio::HGVS::Position->new( position => $position,
								   intron_offset => $intron_offset );
my $p3 = Bio::HGVS::Position->new( position => $position + 10,
								   intron_offset => $intron_offset );
my $p4 = Bio::HGVS::Position->new( position => $position,
								   intron_offset => $intron_offset + 10 );
is(   $p1, $p2, 'complex Positions, equal');
isnt( $p1, $p3, 'complex Positions, different positon, unequal');
isnt( $p1, $p4, 'complex Positions, different offset, unequal');


