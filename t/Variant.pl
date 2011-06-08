#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use Test::More;

use FindBin;
use lib "$FindBin::RealBin/../lib";
use Bio::HGVS::Variant;
use Bio::HGVS::Position;
use Bio::HGVS::Range;

$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;

my @tests = (
  [ 'NM_00123.4:g.56_57AC>GT', {
	name => 'test',
	post => 'GT',
	pre => 'AC',
	ref => 'NM_00123.4',
	type => 'g',
	loc => Bio::HGVS::Range->new( 
	  start => Bio::HGVS::Position->new( position => 56 ),
	  end   => Bio::HGVS::Position->new( position => 57 )
	 ),
  }],

  [ 'NM_00123.4:c.56+3A>T', {
	name => 'test2',
	post => 'T',
	pre => 'A',
	ref => 'NM_00123.4',
	type => 'c',
	loc => Bio::HGVS::Range->new(
	  start => Bio::HGVS::Position->new( position => 56, intron_offset => 3 ),
	 ),
  }],
 );

plan tests => ($#tests+1) * 2;

foreach my $test (@tests) {
  my ($s,$h) = @$test;
  my $v = Bio::HGVS::Variant->new( %$h );
  my @keys = sort keys %$h;
  my @failed = grep { $v->$_ ne $h->{$_} } @keys;
  is( $v, $s, "stringification ($v = $s)");
  ok( $#failed == -1, sprintf('%s: %d keys ok: {%s}; %d failed: {%s}',
							  $v,
							  $#keys+1,join(',',@keys),
							  $#failed+1,join(',',@failed)
							 ));
}
