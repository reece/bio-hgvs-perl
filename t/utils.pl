#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use FindBin;
use lib "$FindBin::RealBin/../lib";

use Bio::HGVS::utils qw(aa1to3 aa3to1 string_diff);

plan tests => 2;

my $aa1 = 'ABCDEFGHI?KLMN?PQRSTUVWXYZ*';
my $aa3 = 'AlaAsxCysAspGluPheGlyHisIle???LysLeuMetAsn???ProGlnArgSerThrSelValTrpXaaTyrGlxTer';

is( aa1to3($aa1), $aa3, 'aa1to3()' );
is( aa3to1($aa3), $aa1, 'aa3to1()' );


#my $aa1a = '-BCD-FGH-?KLMN?PQRST-VWXYZ*';
#diag explain string_diff($aa1,$aa1a);
