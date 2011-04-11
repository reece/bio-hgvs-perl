#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use FindBin;
use lib "$FindBin::RealBin/../lib";
use Bio::HGVS::Position;

plan tests => 24;

my $p;
my $position;
my $intron_offset;

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
