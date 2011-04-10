#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

use FindBin;
use lib "$FindBin::RealBin/../../..";
use Bio::HGVS::Variant;

my @tests = (
  {
	end => 57,
	name => 'test',
	post => 'GT',
	pre => 'AC',
	ref => 'NM_00123.4',
	start => 56,
	type => 'g',
  },
  {
	name => 'test2',
	post => 'T',
	pre => 'A',
	ref => 'NM_00123.4',
	start => 56,
	intron_offset => '+3',
	type => 'c',
  },
 );


foreach my $test (@tests) {
  my $v = Bio::HGVS::Variant->new( %$test );
  my @keys = sort keys %$test;
  my @failed = grep { $v->$_ ne $test->{$_} } @keys;
  ok( $#failed == -1, sprintf('%d keys: {%s}; %d failed: {%s}',
							  $#keys+1,join(',',@keys),
							  $#failed+1,join(',',@failed)
							 ));
}
