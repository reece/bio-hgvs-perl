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
  my ($base_ac,$v) = $ac =~ m/(^\w+)\.(\d+)/;


  my @gene_ids = fetch_genes_by_ac($ac);
  if ($#gene_ids == -1) {
	throw Exception::Class->new("$ac isn't associated with any NCBI genes");
  }
  if ($#gene_ids > 0) {
	throw Exception::Class->new(sprintf('%d genes found for %s; transcript is ambiguous',
										$#gene_ids+1, $ac));
  }
  my $gene_id = $gene_ids[0];


  my $eu = Bio::DB::EUtilities->new(-eutil  => 'efetch',
									-db     => 'gene',
									-id     => $gene_id,
									-email  => $email,
									-retmode => 'xml',
									-retmax => 100);
  my $xml = $eu->get_Response()->content();
  my $dom = XML::LibXML->load_xml(string => $xml);

  my $xp_genasm = __build_xpath(
	qw(/Entrezgene-Set Entrezgene Entrezgene_locus ),
	"Gene-commentary[Gene-commentary_label = 'chromosome']"
   );
  my (@genasms) = grep
	{ $_->findvalue('Gene-commentary_heading') =~ m/^GRCh37/ }
	  $dom->findnodes($xp_genasm);
  return if ($#genasms == -1);
  return if ($#genasms > 0);
  my $genasm = $genasms[0];

  my $xp_seqi = __build_xpath(
	qw(Gene-commentary_seqs Seq-loc Seq-loc_int Seq-interval)
   );
  my ($seqi) = $genasm->findnodes($xp_seqi);

  my $xp_exon = __build_xpath(
	'Gene-commentary_products',
	"Gene-commentary[Gene-commentary_accession/text() "
	  ."= '$base_ac' and Gene-commentary_version/text() = '$v']",
	qw(Gene-commentary_genomic-coords Seq-loc Seq-loc_mix
	   Seq-loc-mix Seq-loc Seq-loc_int Seq-interval
	 )
   );


  return {
	ac => $ac,
	genasm_heading => $genasm->findvalue('Gene-commentary_heading'),
	genasm_ac => $genasm->findvalue('Gene-commentary_accession'),
	genasm_ac_version => $genasm->findvalue('Gene-commentary_version'),
	gene_id => $gene_id,
	exons => [ map { [$_->findvalue('Seq-interval_from')+1, $_->findvalue('Seq-interval_to')+1] }
				 $genasm->findnodes($xp_exon) ],
	start => $seqi->findvalue('Seq-interval_from')+1,
	end => $seqi->findvalue('Seq-interval_to')+1,
	strand => $seqi->findvalue('Seq-interval_strand/Na-strand/@value')
   }
}


sub __build_xpath {
  join('/',@_);
}


1;
