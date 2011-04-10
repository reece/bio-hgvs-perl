#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;

use FindBin;
use lib "$FindBin::RealBin/../../..";
use Bio::HGVS::Errors;
use Bio::HGVS::HGVSVariantParser;


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

);


eval 'use Test::More tests => $#tests + 1';	# deferred until after BEGIN phase

my $hgvs_parser = Bio::HGVS::HGVSVariantParser->new();
foreach my $test (@tests) {
  my ($hgvs,$hash) = @$test;
  try {
	my $r = $hgvs_parser->parse_hash($hgvs);
	#print Dumper $r;
	is_deeply( $r, $hash, "test $hgvs");
  } catch Bio::HGVS::Error with {
	warn $_[0];
  };
}
