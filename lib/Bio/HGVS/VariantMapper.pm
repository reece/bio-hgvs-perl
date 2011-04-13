package Bio::HGVS::VariantMapper;

use strict;
use warnings;

use Carp::Assert;
use Data::Dumper;

use Bio::HGVS::EnsemblConnection;
use Bio::HGVS::Errors;
use Bio::Tools::CodonTable;


use Class::MethodMaker
  [
	scalar => [qw/ conn /] ,
  ];


our %nc_to_chr = (
  'NC_000001' => '1', 'NC_000002' => '2', 'NC_000003' => '3',
  'NC_000004' => '4', 'NC_000005' => '5', 'NC_000006' => '6',
  'NC_000007' => '7', 'NC_000008' => '8', 'NC_000009' => '9',
  'NC_000010' => '10', 'NC_000011' => '11', 'NC_000012' => '12',
  'NC_000013' => '13', 'NC_000014' => '14', 'NC_000015' => '15',
  'NC_000016' => '16', 'NC_000017' => '17', 'NC_000018' => '18',
  'NC_000019' => '19', 'NC_000020' => '20', 'NC_000021' => '21',
  'NC_000022' => '22',
 );
our %chr_to_nc = map { $nc_to_chr{$_} => $_ } keys %nc_to_chr;

my %AA3to1 = (
  'Ala' => 'A', 'Asx' => 'B', 'Cys' => 'C', 'Asp' => 'D',
  'Glu' => 'E', 'Phe' => 'F', 'Gly' => 'G', 'His' => 'H',
  'Ile' => 'I', 'Lys' => 'K', 'Leu' => 'L', 'Met' => 'M',
  'Asn' => 'N', 'Pro' => 'P', 'Gln' => 'Q', 'Arg' => 'R',
  'Ser' => 'S', 'Thr' => 'T', 'Val' => 'V', 'Trp' => 'W',
  'Xaa' => 'X', 'Tyr' => 'Y', 'Glx' => 'Z', 'Ter' => '*',
  'Sel' => 'U'
 );
my %AA1to3 = map { $AA3to1{$_} => $_ } keys %AA3to1;



sub new () {
  my ($class,$conn) = @_;
  my $self = bless({conn=>$conn}, $class);
  if (not defined $self->conn) {
	$self->conn( Bio::HGVS::EnsemblConnection->new() );
	$self->conn->connect()->init_adaptors();
  }
  return $self;
}


sub convert_genomic_to_cds {
  my ($self,@v) = @_;
  map { $self->_genomic_to_cds($_) } @v;
}

sub convert_cds_to_genomic {
  my ($self,@v) = @_;
  map { $self->_cds_to_genomic($_) } @v;
}

sub convert_cds_to_protein {
  my ($self,@v) = @_;
  map { $self->_cds_to_protein($_) } @v;
}

sub convert_protein_to_cds {
  my ($self,@v) = @_;
  map { $self->_protein_to_cds($_) } @v;
}


############################################################################
## INTERNAL FUNCTIONS

sub _genomic_to_cds {
  my ($self,$hgvs_g) = @_;
  my (@rv);

  my $gstart = $hgvs_g->loc->start->position;
  my $gend = (defined $hgvs_g->loc->end) ? $hgvs_g->loc->end->position : $gstart;
  my $chr = $nc_to_chr{$hgvs_g->ref};
  if (not defined $chr) {
	throw Bio::HGVS::Error("Couldn't infer chromosome number from ".$hgvs_g->ref);
  }
  my $slice = $self->conn->{sa}->fetch_by_region( 'chromosome', $chr, $gstart, $gend);

  my (@tx) = @{ $slice->get_all_Transcripts() };
  foreach my $tx (@tx) {
	my $tm = $tx->get_TranscriptMapper();
	$tx = $tx->transform('chromosome');
	my ($coord) = $tx->genomic2cdna($gstart, $gend, 1);

	my $cloc = Bio::HGVS::Range->easy_new(
	  $coord->start - ($tx->cdna_coding_start-1), undef,
	  $coord->end - ($tx->cdna_coding_start-1), undef
	 );

	my (@nm) = @{ $tx->get_all_DBLinks('RefSeq_dna') };
	my $nm = $nm[0]->display_id();

	my $hgvs_c = Bio::HGVS::Variant->new(
	  loc => $cloc,
	  ref => $nm,
	  pre => $hgvs_g->pre,
	  post => $hgvs_g->post,
	  type => 'c',
	 );
	push(@rv,$hgvs_c);
  }
  return @rv;
}

sub _cds_to_genomic {
  my ($self,$hgvs_c) = @_;
  my $id = $hgvs_c->ref;
  my $tx = $self->_fetch_tx($id);
  my $tm = $tx->get_TranscriptMapper();
  my $cpos = $hgvs_c->pos;
  assert(defined $tx->cdna_coding_start, '$tx->cdna_coding_start undefined!');
  assert(defined $hgvs_c->pos->offset, '$hgvs_c->pos->offset undefined; pos=' . "$cpos");
  my $net_offset = $tx->cdna_coding_start + $hgvs_c->pos->offset - 1;
  my ($gpos) = $tm->cdna2genomic($hgvs_c->pos->start + $net_offset,
								 $hgvs_c->pos->end + $net_offset);

  assert( exists $chr_to_nc{$tx->seq_region_name},
		  "Don't know NCBI NC accession for seq_region=$tx->seq_region_name\n");
  my $hgvs_g = Bio::HGVS::GenomicVariant->new(
	ref => $chr_to_nc{$tx->seq_region_name},
	pos => Bio::HGVS::VariantCoordinate->new(start => $gpos->start,
												   end => $gpos->end),
	pre => $hgvs_c->pre,
	post => $hgvs_c->post
   );
  return ($hgvs_g);
}

sub _cds_to_protein {
  my ($self,$hgvs_c) = @_;
  my $cpos = $hgvs_c->pos;
  my $id = $hgvs_c->ref;
  my $tx = $self->_fetch_tx($id);
  my (@np) = @{ $tx->get_all_DBLinks('RefSeq_dna') };
  my $np = $np[0]->display_id();
  my $seq = $tx->seq->seq;
  ($cpos->len > 1) 
	&& throw Bio::HGVS::Error('CDS changes >1 nt not yet supported');
  my $cs = int( ($cpos->start - 1)/3 ) * 3; # codon start, 0 based
  my $rel = ($cpos->start - 1)  % 3;
  my $pre_codon = substr($seq,$cs,3);
  my $post_codon = $pre_codon;
  substr($pre_codon,$rel,1) = $hgvs_c->post;
  my $CT = Bio::Tools::CodonTable->new();	# "standard" human codon table
  my $pre_aa = $CT->translate($pre_codon);
  my $post_aa = $CT->translate($post_codon);
  my $ppos = Bio::HGVS::VariantCoordinate->new(
	start => $cs+$rel+1,
	end => $cs+$rel+1,
   );
  return Bio::HGVS::ProteinVariant->new(
	start => $ppos->start,
	end => $ppos->end,
	pos => $ppos,
	pre => $pre_aa,
	post => $post_aa,
	ref => $np
   );
}

sub _protein_to_cds {
  my ($self,$hgvs_p) = @_;
  my @rv;
  my $id = $hgvs_p->ref;
  my $tx = $self->_fetch_tx($id);
  my (@nm) = @{ $tx->get_all_DBLinks('RefSeq_dna') };
  my $nm = $nm[0]->display_id();
  my $plen = $hgvs_p->pos->end - $hgvs_p->pos->start + 1;
  my $ppos = $hgvs_p->pos;
  my $cpos = Bio::HGVS::VariantCoordinate->new(
	start => 3 * $hgvs_p->pos->start - 2,
	end => 3 * $hgvs_p->pos->end
   );
  my $cpre = substr($tx->seq->seq,$cpos->start-1,$cpos->len);
  my $post = $hgvs_p->post;
  my $post1 = join('', map { $AA3to1{$_} } $hgvs_p->post =~ m/(...)/g);
  my @revtrans = __revtrans($post1);
  foreach my $rt (@revtrans) {
	push(@rv, Bio::HGVS::CDSVariant->new(
	  start => $cpos->start,
	  end => $cpos->end,
	  pos => $cpos,
	  pre => $cpre,
	  post => $rt,
	  ref => $nm
	 ));
  }
  # TODO: 1) consolidate variants, 2) order by min(edits)
  return(@rv);
}

sub _fetch_tx {
  my ($self,$id) = @_;
  my (@tx) = @{ $self->conn->{ta}->fetch_all_by_external_name($id) };
  shouldnt($#tx > 0, "Transcript $id returned more than 1 transcipt");
  if ($#tx == -1) {
	throw Bio::HGVS::Error("Transcript '$id' not found");
  }
  return $tx[0];
}

############################################################################ 
## STATIC METHODS


sub __tx_summary {
  my ($tx) = @_;
  my @ex = @{ $tx->get_all_Exons() };
  sprintf('%s %s %s:%d-%d [%s,%s]  %d exons:(%s)',
		  $tx->display_id,
		  $tx->coord_system_name,
		  $tx->seq_region_name, $tx->seq_region_start, $tx->seq_region_end,
		  $tx->start, $tx->end,
		  $#ex+1, join(',', map {sprintf('%d..%d',$_->start, $_->end)} @ex)
		 );
}

sub __fseq {
  my $seq = shift;
  my $rv = '';
  my $sz = 120;
  my $start = 0;
  while(my $ss = substr($seq,0,$sz,'')) {
	$ss =~ s/.../$& /g;
	$rv .= sprintf("%5d $ss\n",$start+1);
	$start += $sz;
  }
  return $rv;
}

sub __revtrans {
  # For 1-letter protein seq, return all combinations of consistent NA seqs
  # This is intended for very short protein sequences only.
  my ($pseq) = shift;
  my $CT = Bio::Tools::CodonTable->new();	# "standard" human codon table
  my (@caa) = map { [$CT->revtranslate($_)] } split(//,$pseq);
  my (@nseq) = ('');
  foreach my $ca (@caa) {
	@nseq = map { my $s = $_; map { $s.$_ } @$ca } @nseq;
  }
  return @nseq;
}


############################################################################
1;
