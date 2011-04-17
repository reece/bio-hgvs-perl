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
  $h->{lineno} = $.;
  push(@tests,$h);
}
$csv->eof or $csv->error_diag();
close $fh;
printf("read %d test rows\n", $#tests+1);

plan tests => ($#tests+1) * 4; 				# g <-> c and c <-> p

my $parser = Bio::HGVS::VariantParser->new();
my $mapper = Bio::HGVS::VariantMapper->new();

foreach my $t (@tests) {
  my ($rs,$hgvs_g,$hgvs_c,$hgvs_p) = @$t{qw(rsidentifier hgvs_genomic hgvs_cdna hgvs_protein)};

  if (defined $hgvs_g and defined $hgvs_c) {
	my $test;
	$test = sprintf('line %d: genomic_to_cds(%s)', $t->{lineno}, $hgvs_g);
	try {
	  my @r = $mapper->convert_genomic_to_cds( $parser->parse( $hgvs_g ) );
	  ok( in_array( $hgvs_c, @r ), $test )
		or diag("expected $hgvs_c, but got ", (explain @r) || 'nada');
	} catch Bio::HGVS::Error with {
	  fail( "$test: caught".$_[0]->error);
	};

	$test = sprintf('line %d: cds_to_genomic(%s)', $t->{lineno}, $hgvs_c);
	try {
	  my @r = $mapper->convert_cds_to_genomic( $parser->parse( $hgvs_c ) );
	  ok( in_array( $hgvs_g, @r ), $test )
		or diag("expected $hgvs_g, but got ", (explain @r) || 'nada');
	} catch Bio::HGVS::Error with {
	  fail( "$test: caught".$_[0]->error);
	};
  }

  if (defined $hgvs_c and defined $hgvs_p) {
	# TODO: need c<->p here
  }

}

done_testing();



sub in_array ($@) {
  my $v = shift;
  return scalar grep { "$_" eq "$v" } @_;
}
