#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use FindBin;
use lib "$FindBin::RealBin/../lib";
use Bio::HGVS::Variant;
use Bio::HGVS::Position;
use Bio::HGVS::Range;


my @tests = (
  {
	name => 'test',
	post => 'GT',
	pre => 'AC',
	ref => 'NM_00123.4',
	type => 'g',
	loc => Bio::HGVS::Range->new( 
	  start => Bio::HGVS::Position->new( position => 56 ),
	  end   => Bio::HGVS::Position->new( position => 57 )
	 ),
  },
  {
	name => 'test2',
	post => 'T',
	pre => 'A',
	ref => 'NM_00123.4',
	type => 'c',
	loc => Bio::HGVS::Range->new(
	  start => Bio::HGVS::Position->new( position => 56, intron_offset => 3 ),
	 ),
  },
 );


foreach my $test (@tests) {
  my $v = Bio::HGVS::Variant->new( %$test );
  print("* $v\n");
  print("loc = ", $v->loc, "\n");
  my @keys = sort keys %$test;
  my @failed = grep { $v->$_ ne $test->{$_} } @keys;
  ok( $#failed == -1, sprintf('%d keys: {%s}; %d failed: {%s}',
							  $#keys+1,join(',',@keys),
							  $#failed+1,join(',',@failed)
							 ));
}
