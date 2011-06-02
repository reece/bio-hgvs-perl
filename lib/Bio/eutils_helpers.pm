package Bio::eutils_helpers;
use strict;
use warnings;

use XML::LibXML;

use Bio::DB::EUtilities;

my $email = 'reecehart@gmail.com';


sub fetch_genes_by_ac {
  my $ac = shift;
  my $eu = Bio::DB::EUtilities->new(-eutil  => 'esearch',
									-db     => 'gene',
									-term   => $ac,
									-email  => $email,
									-retmax => 25);
  return $eu->get_ids;
}


sub fetch_GRCh37_exon_info_by_gene_id {
  my $gene_id = shift;
  my $eu = Bio::DB::EUtilities->new(-eutil  => 'efetch',
									-db     => 'gene',
									-id     => $gene_id,
									-email  => $email,
									-retmode => 'xml',
									-retmax => 25);
  my $xml = $eu->get_Response()->content();
  my $dom = XML::LibXML->load_xml(string => $xml);

  # First find the GRCh37 chromosome entry
  # There should be only one, but I don't test for this
  my $q1 = join('/',
				qw(/Entrezgene-Set Entrezgene Entrezgene_locus ),
				"Gene-commentary[Gene-commentary_label = 'chromosome']"
			   );
  my ($grch37_chr) = grep
	{ $_->findvalue('Gene-commentary_heading') =~ m/^GRCh37/ }
	  $dom->findnodes($q1);

  my ($base_ac,$v) = $ac =~ m/(^\w+)\.(\d+)/;
  my $q2 = join('/',
				'Gene-commentary_products',
				"Gene-commentary[Gene-commentary_accession/text() = '$base_ac' and Gene-commentary_version/text() = '$v']",
				qw(Gene-commentary_genomic-coords Seq-loc Seq-loc_mix
				   Seq-loc-mix Seq-loc Seq-loc_int Seq-interval
				 )
			   );

  return map { [$_->findvalue('Seq-interval_from')+1, $_->findvalue('Seq-interval_to')+1] } $grch37_chr->findnodes($q2);



1;
