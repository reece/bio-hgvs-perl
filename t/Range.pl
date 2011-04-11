#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use FindBin;
use lib "$FindBin::RealBin/../lib";
use Bio::HGVS::Position;
use Bio::HGVS::Range;

plan tests => 20;

my ($l1,$l2);
my ($p1,$o1) = ( int(rand(1000)), int(rand(50))-25 );
my ($p2,$o2) = ( int(rand(1000)), int(rand(50))-25 );
$p2 += $p1 + 50;							# p2 > p1

# simple range
$l1 = Bio::HGVS::Range->new(
  start => Bio::HGVS::Position->new( position => $p1 ),
  end   => Bio::HGVS::Position->new( position => $p2 )
 );
print("test: ($p1)~($p2) => $l1\n");
isa_ok($l1, 'Bio::HGVS::Range', 'instance created in correct class');
isa_ok($l1, 'Bio::HGVS::Location', 'is a subclass of Bio::HGVS::Location');
is("$l1", "${p1}_$p2", "stringification ($l1 = ${p1}_$p2)");
ok($l1->is_simple, 'is_simple');
is($l1->len, $p2-$p1+1, "length=".$l1->len);

# simple range, no end
$l1 = Bio::HGVS::Range->new(
  start => Bio::HGVS::Position->new( position => $p1 ),
 );
print("test: ($p1) => $l1\n");
isa_ok($l1, 'Bio::HGVS::Range', 'instance created in correct class');
isa_ok($l1, 'Bio::HGVS::Location', 'is a subclass of Bio::HGVS::Location');
is("$l1", "${p1}", "stringification ($l1 = $p1)");
ok($l1->is_simple, 'is_simple');
is($l1->len, 1, "length=".$l1->len);

# range, start == end
$l1 = Bio::HGVS::Range->new(
  start => Bio::HGVS::Position->new( position => $p1 ),
  end => Bio::HGVS::Position->new( position => $p1 ),
 );
print("test: ($p1~$p1) => $l1\n");
isa_ok($l1, 'Bio::HGVS::Range', 'instance created in correct class');
isa_ok($l1, 'Bio::HGVS::Location', 'is a subclass of Bio::HGVS::Location');
is("$l1", "${p1}", "stringification ($l1 = $p1)");
ok($l1->is_simple, 'is_simple');
is($l1->len, 1, "length=".$l1->len);

# complex range
$l1 = Bio::HGVS::Range->new(
  start => Bio::HGVS::Position->new( position => $p1, intron_offset => $o1 ),
  end   => Bio::HGVS::Position->new( position => $p2, intron_offset => $o2 )
 );
print("test: ($p1,$o1)~($p2,$o2) => $l1\n");
isa_ok($l1, 'Bio::HGVS::Range', 'instance created in correct class');
isa_ok($l1, 'Bio::HGVS::Location', 'is a subclass of Bio::HGVS::Location');
like("$l1", qr/$p1.+_$p2.+/, "stringification ($l1)");
ok(not($l1->is_simple), 'not is_simple');
throws_ok { $l1->len } 'Bio::HGVS::Error';
