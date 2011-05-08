#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../lib";
use lib "$FindBin::RealBin/../ext/lib/perl5";

use Data::Dumper;
use Text::CSV;
use Test::More;
use TryCatch;

use Bio::HGVS::Errors;
use Bio::HGVS::Translator;
use Bio::HGVS::Parser;

my @tests;

my $fn = $FindBin::RealBin . '/gauntlet.tsv';

my $csv = Text::CSV->new( { sep_char => "\t",
							blank_is_undef => 1 } )
  or die "Cannot use CSV: ".Text::CSV->error_diag ();

my $fh = *STDIN;
my $row = $csv->getline($fh);
printf("opened $fn with %d cols:\n  %s\n", 
	   $#$row+1, join(',',@$row) );
$csv->column_names( map { $_=~s/\s/_/g;lc($_)} @$row );
while (my $h = $csv->getline_hr($fh)) {
  $h->{lineno} = $.;
  next if (0   and defined $h->{hgvs_genomic}
			   and defined $h->{hgvs_cdna}
			   and defined $h->{hgvs_protein});
  push(@tests,$h);
}
$csv->eof or $csv->error_diag();
printf("read %d test rows\n", $#tests+1);

my $gc = scalar grep { defined $_->{hgvs_genomic} and defined $_->{hgvs_cdna} } @tests;
my $cp = scalar grep { defined $_->{hgvs_cdna} and defined $_->{hgvs_protein} } @tests;
plan tests => 2 * $gc + 2*$cp;

my $parser = Bio::HGVS::Parser->new();
my $mapper = Bio::HGVS::Translator->new();

my %fail_type = map {$_=>0} qw( cds_to_pro pro_to_cds chr_to_cds cds_to_chr);
my %attempted = map {$_=>0} qw( cg cp );
foreach my $t (@tests) {
  my ($rs,$hgvs_g,$hgvs_c,$hgvs_p) = @$t{qw(rsidentifier hgvs_genomic hgvs_cdna hgvs_protein)};

  if (defined $hgvs_g and defined $hgvs_c) {
	my $test;
	$attempted{cg}++;

	$test = sprintf('line %d (%s): chr_to_cds(%s) -> %s',
					$t->{lineno}, $rs||'rs unknown', $hgvs_g, $hgvs_c);
	try {
	  my @r = $mapper->convert_chr_to_cds( $parser->parse( $hgvs_g ) );
	  $test .= sprintf(' (%d returned)',$#r+1);
	  if (not ok( in_array( $hgvs_c, @r ), $test)) {
		diag("expected $hgvs_c, but got ", explain "@r" || 'nada');
		$fail_type{'chr_to_cds'}++;
	  }
	} catch (Bio::HGVS::Error $e) {
	  fail( "$test: $e" );
	  $fail_type{'chr_to_cds'}++;
	};

	$test = sprintf('line %d (%s): cds_to_chr(%s) -> %s',
					$t->{lineno}, $rs||'?', $hgvs_c, $hgvs_g);
	try {
	  my @r = $mapper->convert_cds_to_chr( $parser->parse( $hgvs_c ) );
	  $test .= sprintf(' (%d returned)',$#r+1);
	  if (not ok( in_array( $hgvs_g, @r ), $test)) {
		diag("expected $hgvs_g, but got ", explain "@r" || 'nada');
		$fail_type{'cds_to_chr'}++;
	  }
	} catch (Bio::HGVS::Error $e) {
	  fail( "$test: $e" );
	  $fail_type{'cds_to_chr'}++;
	};
  }

  if (defined $hgvs_c and defined $hgvs_p) {
	my $test;
	$attempted{cp}++;

	$test = sprintf('line %d (%s): cds_to_pro(%s) -> %s',
					$t->{lineno}, $rs||'?', $hgvs_c, $hgvs_p);
	try {
	  my @r = $mapper->convert_cds_to_pro( $parser->parse( $hgvs_c ) );
	  $test .= sprintf(' (%d returned)',$#r+1);
	  if (not ok( in_array( $hgvs_p, @r ), $test)) {
		diag("expected $hgvs_p, but got ", explain "@r" || 'nada');
		$fail_type{'cds_to_pro'}++;
	  }
	} catch (Bio::HGVS::Error $e) {
	  fail( "$test: $e" );
	  $fail_type{'cds_to_pro'}++;
	};

	$test = sprintf('line %d (%s): pro_to_cds(%s) -> %s',
					$t->{lineno}, $rs||'?', $hgvs_p, $hgvs_c);
	try {
	  my @r = $mapper->convert_pro_to_cds( $parser->parse( $hgvs_p ) );
	  $test .= sprintf(' (%d returned)',$#r+1);
	  if (not ok( in_array( $hgvs_c, @r ), $test)) {
		diag("expected $hgvs_c, but got ", explain "@r" || 'nada');
		$fail_type{'pro_to_cds'}++;
	  }
	} catch (Bio::HGVS::Error $e) {
	  fail( "$test: $e" );
	  $fail_type{'pro_to_cds'}++;
	};
  }

}

done_testing();

printf("%4d/%4d %s\n", $fail_type{$_}, $attempted{'cg'}, $_) for qw(chr_to_cds cds_to_chr);
printf("%4d/%4d %s\n", $fail_type{$_}, $attempted{'cp'}, $_) for qw(cds_to_pro pro_to_cds);

############################################################################
sub in_array {
  my $v = shift;
  return scalar grep { "$_" eq "$v" } @_;
}
