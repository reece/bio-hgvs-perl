#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use FindBin;
use lib "$FindBin::RealBin/../lib";

use Bio::HGVS::utils qw(aa1to3 aa3to1 shrink_diff);

plan tests => 11;

my $aa1 = 'ABCDEFGHI?KLMN?PQRSTUVWXYZ*';
my $aa3 = 'AlaAsxCysAspGluPheGlyHisIle???LysLeuMetAsn???ProGlnArgSerThrSelValTrpXaaTyrGlxTer';

is( aa1to3($aa1), $aa3, 'aa1to3()' );
is( aa3to1($aa3), $aa1, 'aa3to1()' );


my @shrink_tests = (
  [ 'ACGT', 'ACGT', undef ],
  [ 'ACGT', 'XCGT', [0,1] ],
  [ 'ACGT', 'AXGT', [1,1] ],
  [ 'ACGT', 'ACXT', [2,1] ],
  [ 'ACGT', 'ACGX', [3,1] ],
  [ 'ACGT', 'XCGX', [0,4] ],
  [ 'ACGT', 'AXXT', [1,2] ],
  [ 'ACGT', 'AXXT', [1,2] ],
  [ 'ACGT', 'XCGX', [0,4] ],
);
foreach my $st (@shrink_tests) {
  my $sl = shrink_diff($st->[0],$st->[1]);
  is_deeply( $sl, $st->[2], sprintf('shrink_diff(%s,%s)',$st->[0],$st->[1]) );
}
