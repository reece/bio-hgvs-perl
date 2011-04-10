#!/usr/bin/perl
# variant-mapper-test -- map HGVS variants between coordinate systems
# 2011-03-21 12:46 Reece Hart <reecehart@gmail.com>
#

use strict;
use warnings;

use Test::More;
use Data::Dumper;

use FindBin;
use lib "$FindBin::RealBin/../../..";
use Bio::HGVS::Errors;
use Bio::HGVS::Variant;
use Bio::HGVS::VariantMapper;
use Bio::HGVS::HGVSVariantParser;


$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;

# http://www.ncbi.nlm.nih.gov/sites/varvu?gene=7172&rs=1800460
my @tests = (
  [qw( rs12201199 NC_000006:g.18139802T>A
		 NG_012137.1:g.20573T>A NM_000367.2:c.419+94T>A                      )],
  [qw( rs56019966 NC_000006:g.18139272G>A
		 NG_012137.1:g.21103G>A NM_000367.2:c.420-4G>A						 )],
  [qw( rs1800462  NC_000006:g.18143955G>C
		 NG_012137.1:g.16420G>C NM_000367.2:c.238G>C NP_000358.1:p.Ala80Pro	 )],
  [qw( rs1800460  NC_000006:g.18139228G>A
		 NG_012137.1:g.21147G>A NM_000367.2:c.460G>A NP_000358.1:p.Ala154Thr )],
  [qw( rs74423290 NC_000006:g.18134115C>G
		 NG_012137.1:g.26260C>G NM_000367.2:c.500C>G NP_000358.1:p.Ala167Gly )],
  [qw( rs56161402 NC_000006:g.18130993G>A
		 NG_012137.1:g.29382G>A NM_000367.2:c.644G>A NP_000358.1:p.Arg215His )],
  [qw( rs1142345  NC_000006:g.18130918A>G
		 NG_012137.1:g.29457A>G NM_000367.2:c.719A>G NP_000358.1:p.Tyr240Cys )],
);

plan tests => ($#tests+1) * 2; 				# no. tests per @tests row


my $vp = Bio::HGVS::HGVSVariantParser->new();
my $vm = Bio::HGVS::VariantMapper->new();

foreach my $test (@tests) {
  my ($rs,$hgvs_chr,$hgvs_g,$hgvs_c,$hgvs_p) = @$test;
  my $v = $vp->parse($hgvs_chr);
  my (@c) = $vm->convert_genomic_to_cds($v);
  ok($#c == 0, "$hgvs_chr has exactly one CDS translation");
  is($hgvs_c, $c[0], "$hgvs_chr -> CDS translation correct");
}


__END__

sub print_g_query {
  my ($v) = @_;
  foreach my $c (@c) {
	print("  -> c: @c\n");
	my (@p) = $vm->convert_cds_to_protein($c);
	foreach my $p (@p) {
	  print("    -> p: $p\n");
	}
  }
}

sub print_c_query {
  my ($v) = @_;
  my @g = $vm->convert_cds_to_genomic($v);
  foreach my $g (@g) {
	print("  -> g: $g\n");
  }
  my @p = $vm->convert_cds_to_protein($v);
  foreach my $p (@p) {
	print("  -> p: $p\n");
  }
}

sub print_p_query {
  my ($v) = @_;
  my @c = $vm->convert_protein_to_cds($v);
  foreach my $c (@c) {
	print("  -> c: $c\n");
	my @g = $vm->convert_cds_to_genomic($c);
	foreach my $g (@g) {
	  print("    -> g: $g\n");
	}
  }
}
