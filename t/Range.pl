#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use Test::More;
use Test::Exception;

use FindBin;
use lib "$FindBin::RealBin/../lib";
use Bio::HGVS::Position;
use Bio::HGVS::Range;

$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;

plan tests => 1370;

my ($l1,$l2,$l3);
my ($p1,$o1) = ( 100, -11 );
my ($p2,$o2) = ( 200, +21 );

# new/easy_new, simple point
$l1 = Bio::HGVS::Range->new(
  start => Bio::HGVS::Position->new( position => $p1 ),
 );
$l2 = Bio::HGVS::Range->easy_new( $p1 );
isa_ok($l1, 'Bio::HGVS::Range', 'instance created in correct class');
isa_ok($l1, 'Bio::HGVS::Location', 'is a subclass of Bio::HGVS::Location');
isa_ok($l2, 'Bio::HGVS::Range', 'instance created in correct class');
isa_ok($l2, 'Bio::HGVS::Location', 'is a subclass of Bio::HGVS::Location');
is($l1,$l2, 'new == easy_new for simple point');

# new/easy_new, complex point
$l1 = Bio::HGVS::Range->new(
  start => Bio::HGVS::Position->new( position => $p1, intron_offset => $o1 ),
 );
$l2 = Bio::HGVS::Range->easy_new( $p1, $o1 );
isa_ok($l1, 'Bio::HGVS::Range', 'instance created in correct class');
isa_ok($l1, 'Bio::HGVS::Location', 'is a subclass of Bio::HGVS::Location');
isa_ok($l2, 'Bio::HGVS::Range', 'instance created in correct class');
isa_ok($l2, 'Bio::HGVS::Location', 'is a subclass of Bio::HGVS::Location');
is($l1,$l2, 'new == easy_new for complex point');

# new/easy_new, simple range
$l1 = Bio::HGVS::Range->new(
  start => Bio::HGVS::Position->new( position => $p1 ),
  end => Bio::HGVS::Position->new( position => $p2 ),
 );
$l2 = Bio::HGVS::Range->easy_new( $p1, undef, $p2, undef );
isa_ok($l1, 'Bio::HGVS::Range', 'instance created in correct class');
isa_ok($l1, 'Bio::HGVS::Location', 'is a subclass of Bio::HGVS::Location');
isa_ok($l2, 'Bio::HGVS::Range', 'instance created in correct class');
isa_ok($l2, 'Bio::HGVS::Location', 'is a subclass of Bio::HGVS::Location');
is($l1,$l2, 'new == easy_new for simple range');

# new/easy_new, complex range
$l1 = Bio::HGVS::Range->new(
  start => Bio::HGVS::Position->new( position => $p1, intron_offset => $o1 ),
  end   => Bio::HGVS::Position->new( position => $p2, intron_offset => $o2 ),
 );
$l2 = Bio::HGVS::Range->easy_new( $p1, $o1, $p2, $o2 );
isa_ok($l1, 'Bio::HGVS::Range', 'instance created in correct class');
isa_ok($l1, 'Bio::HGVS::Location', 'is a subclass of Bio::HGVS::Location');
isa_ok($l2, 'Bio::HGVS::Range', 'instance created in correct class');
isa_ok($l2, 'Bio::HGVS::Location', 'is a subclass of Bio::HGVS::Location');
is($l1,$l2, 'new == easy_new for complex range');


# simple range
$l1 = Bio::HGVS::Range->new(
  start => Bio::HGVS::Position->new( position => $p1 ),
  end   => Bio::HGVS::Position->new( position => $p2 )
 );
print("test: ($p1)~($p2) => $l1\n");
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


### eq/ne testing
# build 2 sets of positions, %pA and %pB, copies of each other, with
# combinations of equal and different positions and offsets (2 positions *
# 3 offsets).  Ranges should be equal iff hash keys are equal.
my (%pA,%pB);
for(my $pi = 1; $pi<=2; $pi++) {
  my $p = 10 * $pi;
  my $t = $p;
  $pA{$t} = Bio::HGVS::Position->new( position => $p );
  $pB{$t} = Bio::HGVS::Position->new( position => $p );
  for(my $oi = 1; $oi<=2; $oi++) {
	my $o = $p + $oi;
	my $t = $o;
	$pA{$t} = Bio::HGVS::Position->new( position => $p, intron_offset => $o );
	$pB{$t} = Bio::HGVS::Position->new( position => $p, intron_offset => $o );
  }
}

# start only
foreach my $kA (sort keys %pA) {
  my $l1 = Bio::HGVS::Range->new( start => $pA{$kA} );
  foreach my $kB (sort keys %pB) {
	my $l2 = Bio::HGVS::Range->new( start => $pB{$kB} );
	if ($kA eq $kB) {
	  ok( $l1 eq $l2, "$l1 eq $l2" );
	} else {
	  ok( $l1 ne $l2, "$l1 ne $l2" );
	}
  }
}

# with end ranges
foreach my $kAs (sort keys %pA) {
  foreach my $kAe (sort keys %pA) {
	my $l1 = Bio::HGVS::Range->new( start => $pA{$kAs}, end => $pA{$kAe} );
	foreach my $kBs (sort keys %pB) {
	  foreach my $kBe (sort keys %pB) {
		my $l2 = Bio::HGVS::Range->new( start => $pB{$kBs}, end => $pA{$kBe} );
		if ( ($kAs eq $kBs) and ($kAe eq $kBe) ) {
		  ok( $l1 eq $l2, "$l1 eq $l2" );
		} else {
		  ok( $l1 ne $l2, "$l1 ne $l2" );
		}
	  }
	}
  }
}
