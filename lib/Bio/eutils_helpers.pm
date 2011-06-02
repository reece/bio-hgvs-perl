package Bio::eutils_helpers;
use strict;
use warnings;

use XML::LibXML;
use Exception::Class;

use Bio::DB::EUtilities;

my $email = 'reecehart@gmail.com';


sub fetch_genes_by_ac {
  my $ac = shift;
  my $eu = Bio::DB::EUtilities->new(-eutil  => 'esearch',
									-db     => 'gene',
									-term   => $ac,
									-email  => $email,
									-retmax => 100);
  return $eu->get_ids;
}


sub fetch_transcript_info_by_ac {
  my $ac = shift;
  my @gene_ids = fetch_genes_by_ac($ac);
  if ($#gene_ids == -1) {
	throw Exception::Class->new("$ac isn't associated with any NCBI genes");
  }
  if ($#gene_ids > 0) {
	throw Exception::Class->new(sprintf('%d genes found for %s; transcript is ambiguous',
										$#gene_ids+1, $ac));
  }
  return {
	ac => $ac,
	gene_id => $gene_ids[0],
	exons => [ __fetch_GRCh37_exons_by_gene_id($gene_ids[0],$ac) ],
   }
}


############################################################################

sub __fetch_GRCh37_exons_by_gene_id {
  my ($gene_id,$ac) = @_;
  my ($base_ac,$v) = $ac =~ m/(^\w+)\.(\d+)/;

  my $eu = Bio::DB::EUtilities->new(-eutil  => 'efetch',
									-db     => 'gene',
									-id     => $gene_id,
									-email  => $email,
									-retmode => 'xml',
									-retmax => 100);
  my $xml = $eu->get_Response()->content();
  my $dom = XML::LibXML->load_xml(string => $xml);

  my $q1 = __build_xpath(
	qw(/Entrezgene-Set Entrezgene Entrezgene_locus ),
	"Gene-commentary[Gene-commentary_label = 'chromosome']"
   );
  my (@genasms) = grep
	{ $_->findvalue('Gene-commentary_heading') =~ m/^GRCh37/ }
	  $dom->findnodes($q1);
  return if ($#genasms == -1);
  return if ($#genasms > 0);
  my $genasm = $genasms[0];

  my $q2 = __build_xpath(
	'Gene-commentary_products',
	"Gene-commentary[Gene-commentary_accession/text() "
	  ."= '$base_ac' and Gene-commentary_version/text() = '$v']",
	qw(Gene-commentary_genomic-coords Seq-loc Seq-loc_mix
	   Seq-loc-mix Seq-loc Seq-loc_int Seq-interval
	 )
   );

  return (
	map { [$_->findvalue('Seq-interval_from')+1, $_->findvalue('Seq-interval_to')+1] }
	  $genasm->findnodes($q2)
	 );
}


sub __build_xpath {
  join('/',@_);
}


1;
