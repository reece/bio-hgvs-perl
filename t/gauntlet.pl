#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use Text::CSV;
use Test::More;

use FindBin;
use lib "$FindBin::RealBin/../lib";
use Bio::HGVS::Errors;
use Bio::HGVS::VariantMapper;
use Bio::HGVS::VariantParser;

my @tests;

my $fn = $FindBin::RealBin . '/gauntlet.tsv';

my $csv = Text::CSV->new( { sep_char => "\t",
							blank_is_undef => 1 } )
  or die "Cannot use CSV: ".Text::CSV->error_diag ();

my $fh;
open($fh, "<:encoding(utf8)", $fn)
  or die "$fn: $!";
my $row = $csv->getline($fh);
printf("opened $fn with %d cols:\n  %s\n", 
	   $#$row+1, join(',',@$row) );
$csv->column_names( map { $_=~s/\s/_/g;lc($_)} @$row );
while (my $h = $csv->getline_hr($fh)) {
  push(@tests,$h);
}
$csv->eof or $csv->error_diag();
close $fh;
printf("read %d test rows\n", $#tests+1);


my $parser = Bio::HGVS::VariantParser->new();
my $mapper = Bio::HGVS::VariantMapper->new();

for(my $ti = 0; $ti<@tests; $ti++) {
  my $t = $tests[$ti];
  my ($rs,$hgvs_g,$hgvs_c,$hgvs_p) = @$t{qw(rsidentifier hgvs_genomic hgvs_cdna hgvs_protein)};
  my $lineno = $ti+2; # 1 for header, 1 for 0-based arrays and 1-based line no.
  printf("\n* line %d: %s , %s , %s , %s\n", 
		$lineno,
		$rs || '?',
		$hgvs_g || '?',
		$hgvs_c || '?',
		$hgvs_p || '?'
	   ) if 0;

  my @r;
  my $nmatch;

  if (defined $hgvs_g and defined $hgvs_c) {
	@r = $mapper->convert_genomic_to_cds( $parser->parse( $hgvs_g ) );
	$nmatch = grep { "$_" eq "$hgvs_c" } @r;
	ok($nmatch != 0 , sprintf('line %d. Expected CDS (%s) in %d results {%s}', 
							  $lineno, $hgvs_c, $#r+1, join(',',@r)) );

	try {
	  @r = $mapper->convert_cds_to_genomic( $parser->parse( $hgvs_c ) );
	  $nmatch = grep { "$_" eq "$hgvs_g" } @r;
	  ok($nmatch != 0 , sprintf('line %d. Expected genomic (%s) in %d results {%s}', 
								$lineno, $hgvs_g, $#r+1, join(',',@r)) );
	} catch Bio::HGVS::Error with {
	  fail(sprintf('line %d. c2g(%s): caught %s',$lineno,$hgvs_c,$_[0]));
	};
  }

}

done_testing();