#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use Test::More;

use FindBin;
use lib "$FindBin::RealBin/../lib";
use Bio::HGVS::Errors;
use Bio::HGVS::Parser;


$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;

my @tests = (
  [ 'NM_00123.4:g.56A>C', {
	'end' => '56',
	'op' => 'sub',
	'post' => 'C',
	'pre' => 'A',
	'ref' => 'NM_00123.4',
	'start' => '56',
	'type' => 'g'
   }],

  [ 'NM_00123.4:g.56_58ACG>CGT', {
	'end' => '58',
	'op' => 'sub',
	'post' => 'CGT',
	'pre' => 'ACG',
	'ref' => 'NM_00123.4',
	'start' => '56',
	'type' => 'g'
   }],

  [ 'NM_00123.4:c.56+6A>C', {
	'intron_offset' => '+6',
	'op' => 'sub',
	'post' => 'C',
	'pre' => 'A',
	'ref' => 'NM_00123.4',
	'start' => '56',
	'type' => 'c'
   }],

  [ 'NP_00123.4:p.Cys56Trp', {
	'op' => 'sub',
	'post' => 'Trp',
	'pre' => 'Cys',
	'ref' => 'NP_00123.4',
	'start' => '56',
	'type' => 'p'
   }],

  [ 'NM_00123.4:g.56_57insAACCGG', {
	'end' => '57',
	'op' => 'ins',
	'post' => 'AACCGG',
	'pre' => '',
	'ref' => 'NM_00123.4',
	'start' => '56',
	'type' => 'g'
   }],

  [ 'NM_00123.4:g.56_57del', {
	'end' => '57',
	'op' => 'del',
	'post' => '',
	'pre' => '',
	'ref' => 'NM_00123.4',
	'start' => '56',
	'type' => 'g'
   }],

  [ 'NM_00123.4:g.56_57delAC', {
	'end' => '57',
	'op' => 'del',
	'post' => '',
	'pre' => 'AC',
	'ref' => 'NM_00123.4',
	'start' => '56',
	'type' => 'g'
   }],

  [ 'NM_00123.4:g.56_57AC(5_10)', {
	'end' => '57',
	'op' => 'rpt',
	'post' => '',
	'pre' => 'AC',
	'ref' => 'NM_00123.4',
	'start' => '56',
	'type' => 'g',
	'rpt_min' => 5,
	'rpt_max' => 10,
   }],
);

plan tests => 2 * ($#tests + 1);

my $hgvs_parser = Bio::HGVS::Parser->new();
foreach my $test (@tests) {
  my ($hgvs,$hash) = @$test;
  try {
	my $r = $hgvs_parser->parse_hash($hgvs);
	is_deeply( $r, $hash, "parse_hash $hgvs");
	my $v = $hgvs_parser->parse($hgvs);
	is( $v, $hgvs, "stringified okay ($v =?= $hgvs)" );
  } catch Bio::HGVS::Error with {
	warn $_[0];
  };
}
