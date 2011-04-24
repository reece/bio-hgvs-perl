#!/usr/bin/perl
# variant-mapper-test -- map HGVS variants between coordinate systems
# 2011-03-21 12:46 Reece Hart <reecehart@gmail.com>
#

use strict;
use warnings;

use Test::More;
use Data::Dumper;

use FindBin;
use lib "$FindBin::RealBin/../lib";
use Bio::HGVS::Errors;
use Bio::HGVS::Variant;
use Bio::HGVS::VariantMapper;
use Bio::HGVS::VariantParser;

$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;

# http://www.ncbi.nlm.nih.gov/sites/varvu?gene=7172&rs=1800460
my @tests = (
  # "Easy" SNV tests with CDS changes:
  [qw( NC_000006:g.18143955G>C NM_000367.2:c.238G>C NP_000358.1:p.Ala80Pro	)],
  [qw( NC_000006:g.18139228G>A NM_000367.2:c.460G>A NP_000358.1:p.Ala154Thr )],
  [qw( NC_000007.13:g.100224453T>G NM_003227.3:c.2069A>C NP_003218.2:p.Gln690Pro )],

  # Intronic SNV tests without CDS changes:
  [qw( NC_000006:g.18139802T>A NM_000367.2:c.419+94T>A                      )],
  [qw( NC_000006:g.18139272G>A NM_000367.2:c.420-4G>A						)],

  # multiple transcripts (TBD):
  # NC_000003.11:g.8775702G>A NM_033337.2:c.114+26G>A NM_033337.1:c.114+26G>A NM_001234.3:c.114+26G>A
);

plan tests => ($#tests+1) * 6; 				# no. tests per @tests row

my $vp = Bio::HGVS::VariantParser->new();
my $vm = Bio::HGVS::VariantMapper->new();

foreach my $test (@tests) {
  my ($hgvs_chr,$hgvs_c,$hgvs_p) = @$test;
  warn("\n* @$test\n");
  
  my $v;									# Bio::HGVS::variant object
  my @x;									# translated results

  # genomic to cDNA
  $v = $vp->parse($hgvs_chr);
  is($v, $hgvs_chr, "stringification okay ($v)");
  (@x) = $vm->convert_chr_to_cds($v);
  ok($#x == 0, "Exactly one genomic_to_cds result for $v");
  is($x[0], $hgvs_c, "Translation correct ($hgvs_chr -> $x[0])");

  # cDNA to genomic
  $v = $vp->parse($hgvs_c);
  is($v, $hgvs_c, "stringification okay ($v)");
  (@x) = $vm->convert_cds_to_chr($v);
  ok($#x == 0, "Exactly one cds_to_genomic result for $v");
  is($x[0], $hgvs_chr, "Translation correct ($hgvs_c -> $x[0])");

  # cDNA to protein
  $v = $vp->parse($hgvs_c);
  is($v, $hgvs_c, "stringification okay ($v)");
  (@x) = $vm->convert_cds_to_pro($v);
  ok($#x == 0, "Exactly one cds_to_protein result for $v");
  is($x[0], $hgvs_p, "Translation correct ($hgvs_c -> $x[0])");

  # protein to CDS
  $v = $vp->parse($hgvs_p);
  is($v, $hgvs_p, "stringification okay ($v)");
  (@x) = $vm->convert_pro_to_cds($v);
  #ok($#x == 0, "Exactly one pro_to_cds result for $v");
  is($x[0], $hgvs_c, "Translation correct ($hgvs_p -> $x[0])");
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
