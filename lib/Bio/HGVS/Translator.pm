package Bio::HGVS::Translator;

use strict;
use warnings;

use Carp::Assert;
use Data::Dumper;
#use Log::Log4perl;
use TryCatch;

use Bio::PrimarySeq;

use Bio::HGVS;
use Bio::HGVS::EnsemblConnection;
use Bio::HGVS::Errors;
use Bio::HGVS::LocationMapper;
use Bio::Tools::CodonTable;
use Bio::HGVS::utils qw(aa1to3 aa3to1 shrink_diff);


use Moose;
use MooseX::Aliases;
has 'ens_conn' => (
  is => 'ro',
  alias => 'ec'
 );




our %nc_to_chr = (
  # 2011-04-14 16:08 Reece Hart <reecehart@gmail.com>: GRCh37.p2 versions
  'NC_000001.10' =>  '1', 'NC_000002.11' =>  '2', 'NC_000003.11' => '3',
  'NC_000004.11' =>  '4', 'NC_000005.9'  =>  '5', 'NC_000006.11' => '6',
  'NC_000007.13' =>  '7', 'NC_000008.10' =>  '8', 'NC_000009.11' => '9',
  'NC_000010.10' => '10', 'NC_000011.9'  => '11', 'NC_000012.11' => '12',
  'NC_000013.10' => '13', 'NC_000014.10' => '14', 'NC_000015.9'  => '15',
  'NC_000016.9'  => '16', 'NC_000017.10' => '17', 'NC_000018.9'  => '18',
  'NC_000019.9'  => '19', 'NC_000020.10' => '20', 'NC_000021.8'  => '21',
  'NC_000022.10' => '22', 'NC_000023.10' =>  'X', 'NC_000024.9'  => 'Y',
 );
our %chr_to_nc = map { $nc_to_chr{$_} => $_ } keys %nc_to_chr;




sub translate1 {
  my ($self,$v) = @_;
  my %rv = (
	query => $v,
	error => undef,
   );

  try {
	$rv{query_type} = $v->type;
	if ($v->type eq 'g') {
	  @{$rv{g}} = ($v);
	  try {
		@{$rv{c}} = $self->convert_chr_to_cds(@{$rv{g}});
	  } catch (Bio::HGVS::Error $e) {
		@{$rv{c}} = $e;
	  };
	  try {
		@{$rv{p}} = $self->convert_cds_to_pro(@{$rv{c}});
	  } catch (Bio::HGVS::Error $e) {
		@{$rv{p}} = $e;
	  };
	} elsif ($v->type eq 'c') {
	  @{$rv{c}} = ($v);
	  try {
		@{$rv{g}} = $self->convert_cds_to_chr(@{$rv{c}});
	  } catch (Bio::HGVS::Error $e) {
		@{$rv{g}} = $e;
	  };
	  try {
		@{$rv{p}} = $self->convert_cds_to_pro(@{$rv{c}});
	  } catch (Bio::HGVS::Error $e) {
		@{$rv{p}} = $e;
	  };
	} elsif ($v->type eq 'p') {
	  @{$rv{p}} = ($v);
	  try {
		@{$rv{c}} = $self->convert_pro_to_cds(@{$rv{p}});
	  } catch (Bio::HGVS::Error $e) {
		@{$rv{c}} = $e;
	  };
	  try {
		@{$rv{g}} = $self->convert_cds_to_chr(@{$rv{c}});
	  } catch (Bio::HGVS::Error $e) {
		@{$rv{g}} = $e;
	  };
	}
  } catch (Bio::HGVS::Error $e) {
	$rv{error} = $e;
  };
  return \%rv;
}




#sub g_to_1g {
#  my ($self,$v,$ac) = @_;
#  assert( ref($v) and $v->isa('Bio::HGVS::Variant') and $v->type eq 'g',
#		  "$v is not a genomic variant" );
#}



sub convert_chr_to_cds {
  my ($self,@v) = @_;
  map { $self->_chr_to_cds($_) } @v;
}

sub convert_cds_to_chr {
  my ($self,@v) = @_;
  map { $self->_cds_to_chr($_) } @v;
}

sub convert_cds_to_pro {
  my ($self,@v) = @_;
  map { $self->_cds_to_pro($_) } @v;
}

sub convert_pro_to_cds {
  my ($self,@v) = @_;
  map { $self->_pro_to_cds($_) } @v;
}


############################################################################
## INTERNAL FUNCTIONS

sub _chr_to_cds {
  my ($self,$hgvs_g) = @_;
  #my $logger = Log::Log4perl->get_logger();
  if ($hgvs_g->type ne 'g') {
	Bio::HGVS::TypeError->throw('HGVS g. variant expected');
  }
  my (@rv);

  my $gstart = $hgvs_g->loc->start->position;
  my $gend = (defined $hgvs_g->loc->end) ? $hgvs_g->loc->end->position : $gstart;
  my $chr = $nc_to_chr{$hgvs_g->ref};
  if (not defined $chr) {
	Bio::HGVS::Error->throw("Couldn't infer chromosome number from ".$hgvs_g->ref);
  }
  my $slice = $self->ec->{sa}->fetch_by_region('chromosome',
													 $chr, $gstart, $gend);

  my (@tx) = @{ $slice->get_all_Transcripts() };
  foreach my $tx (@tx) {
	my $lm = Bio::HGVS::LocationMapper->new( { transcript => $tx } );
	my $cloc = $lm->chr_to_cds($hgvs_g->loc);
	next unless defined $cloc;
	my (@nm) = @{ $tx->get_all_DBLinks('RefSeq_mRNA') };
	my $ac = (defined $nm[0] ? $nm[0]->display_id() : $tx->display_id());
	if ($cloc->end->position > $tx->length) {
	  warn(sprintf('Transcript %s skipped because cds loc > transcript length (%s>%d)',
				   $ac, $cloc, $tx->translation->length));
	}

	my ($pre,$post) = (Bio::PrimarySeq->new( -seq => $hgvs_g->pre,
											 -alphabet => 'dna' ),
					   Bio::PrimarySeq->new( -seq => $hgvs_g->post,
											 -alphabet => 'dna' ) );
	if ($tx->strand == -1) {
	  $pre = $pre->revcom;
	  $post = $post->revcom;
	}

	my $hgvs_c = Bio::HGVS::Variant->new(
	  loc => $cloc,
	  ref => $ac,
	  pre => $pre->seq,
	  post => $post->seq,
	  type => 'c',
	  rpt_min => $hgvs_g->rpt_min,
	  rpt_max => $hgvs_g->rpt_max,
	 );
	push(@rv,$hgvs_c);
  }
  return @rv;
}

sub _cds_to_chr {
  my ($self,$hgvs_c) = @_;
  #my $logger = Log::Log4perl->get_logger();
  if ($hgvs_c->type ne 'c') {
	Bio::HGVS::TypeError->throw('HGVS c. variant expected');
  }
  my (@tx) = $self->_fetch_tx($hgvs_c->ref);
  if ($#tx > 0) {
	Bio::HGVS::Error->throw(
	  sprintf('More than one trancript for %s',$hgvs_c->ref));
  }
  my $tx = $tx[0];
  if (not defined $tx) {
	Bio::HGVS::Error->throw(
	  sprintf('No trancript found for %s',$hgvs_c->ref));
  }
  my $lm = Bio::HGVS::LocationMapper->new( { transcript => $tx } );
  my $gloc = $lm->cds_to_chr( $hgvs_c->loc );
  my ($pre,$post) = (Bio::PrimarySeq->new( -seq => $hgvs_c->pre,
										   -alphabet => 'dna' ),
					 Bio::PrimarySeq->new( -seq => $hgvs_c->post,
										   -alphabet => 'dna' ) );
  # FIXME: Deletions across exon boundaries are not handled correctly.
  # e.g., NM_000492.3:c.1574_1590del
  if ($tx->strand == -1) {
	$pre = $pre->revcom;
	$post = $post->revcom;
  }
  assert( exists $chr_to_nc{$tx->seq_region_name},
		  "Can't find NCBI NC accession for seq_region=$tx->seq_region_name\n");
  my $hgvs_g = Bio::HGVS::Variant->new(
	ref => $chr_to_nc{$tx->seq_region_name},
	loc => $gloc,
	pre => $pre->seq,
	post => $post->seq,
	type => 'g',
	rpt_min => $hgvs_c->rpt_min,
	rpt_max => $hgvs_c->rpt_max,
   );
  return ($hgvs_g);
}

sub _cds_to_pro {
  my ($self,$hgvs_c) = @_;
  #my $logger = Log::Log4perl->get_logger();
  if ($hgvs_c->type ne 'c') {
	Bio::HGVS::TypeError->throw('HGVS c. variant expected');
  }
  if ($hgvs_c->variant_type ne 'subst') {
	Bio::HGVS::NotImplementedError->throw(
	  "$hgvs_c: only substitution variants are currently supported for CDS-to-protein translation");
  }

  my (@tx) = $self->_fetch_tx($hgvs_c->ref);
  if ($#tx > 0) {
	Bio::HGVS::Error->throw(
	  sprintf('More that one trancript for %s',$hgvs_c->ref));
  }
  my $tx = $tx[0];
  if (not defined $tx) {
	Bio::HGVS::Error->throw(
	  sprintf('No trancript found for %s',$hgvs_c->ref));
  }
  if (not defined $tx->translate) {
	return undef;
  }

  my $lm = Bio::HGVS::LocationMapper->new( { transcript => $tx } );
  my $ploc = $lm->cds_to_pro($hgvs_c->loc);
  return unless defined $ploc;

  my (@np) = @{ $tx->get_all_DBLinks('RefSeq_peptide') };
  my $np = (defined $np[0] ? $np[0]->display_id() : $tx->translate->display_id());

  my $pre_seq = $tx->translateable_seq;

  ## FIXME: extend the following for more than just subst changes
  #my $post_seq = $pre_seq;
  #substr($post_seq,
  #       $hgvs_c->loc->start->position-1,
  #       $hgvs_c->loc->len) = $hgvs_c->post;
  #warn(sprintf("#%40.40s\n<%40.40s\n>%40.40s\n",'1234567890'x5,$pre_seq,$post_seq));
  my $cs = int( ($hgvs_c->loc->start->position - 1)/3 ) * 3;
  my $phase = ($hgvs_c->loc->start->position - 1) % 3;
  if ($cs+3 > length($pre_seq)) {   # should this be '$tx->length' ?
	return;
	# this throw fails to report the real cause. I hate perl's lack of real exceptions.
	Bio::HGVS::Error->throw(
	  sprintf('Position %d outside of CDS sequences for %s with sequence length %d',
			  $cs+3, $hgvs_c, length($pre_seq))
	 );
  }
  #warn(sprintf(
  #	'%s; len=%d; cs=%d, ps_len=%d',
  #	$tx->display_id, $tx->length, $cs, length($pre_seq)
  # ));

  my $pre_codon = substr($pre_seq,$cs,3);
  my $post_codon = $pre_codon;
  substr($post_codon,$phase,length($hgvs_c->pre)) = $hgvs_c->post;
  my $CT = Bio::Tools::CodonTable->new();	# "standard" human codon table
  my $pre = aa1to3( $CT->translate($pre_codon ) );
  my $post = aa1to3( $CT->translate($post_codon) );

  return Bio::HGVS::Variant->new(
	loc => $ploc,
	pre =>  $pre,
	post => $post,
	ref => $np,
	type => 'p'
   );
}

sub _pro_to_cds {
  my ($self,$hgvs_p) = @_;
  #my $logger = Log::Log4perl->get_logger();
  if ($hgvs_p->type ne 'p') {
	Bio::HGVS::TypeError->throw('HGVS p. variant expected');
  }
  my (@tx) = $self->_fetch_tx($hgvs_p->ref);
  if ($#tx == -1) {
	Bio::HGVS::Error->throw(
	  sprintf('Transcript %s not found',$hgvs_p->ref));
  }

  my @rv;
  foreach my $tx (@tx) {
	my $lm = Bio::HGVS::LocationMapper->new({transcript=>$tx});
	my $cloc = $lm->pro_to_cds( $hgvs_p->loc );
	my $cpre = substr($tx->translateable_seq,
					  $cloc->start->position - 1,
					  $cloc->len);

	my (@nm) = @{ $tx->get_all_DBLinks('RefSeq_mRNA') };
	my $ac = (defined $nm[0] ? $nm[0]->display_id() : $tx->display_id());

	my @revtrans = __revtrans( aa3to1( $hgvs_p->post ) );
	foreach my $rt (@revtrans) {
	  $rt = uc($rt);
	  my $di = shrink_diff($cpre,$rt);
	  next unless defined $di;				# => No change?!
	  my ($s,$l) = @$di;
	  my $cpre_s = substr($cpre,$s,$l);
	  my $rt_s = substr($rt,$s,$l);
	  my $cloc_s = Bio::HGVS::Range->easy_new(
		$cloc->start->position + $s, undef,
		$cloc->start->position + $s + $l - 1, undef
	   );
	  push(@rv, Bio::HGVS::Variant->new(
		loc => $cloc_s,
		pre => $cpre_s,
		post => $rt_s,
		ref => $ac,
		type => 'c'
	   ));
	}
  }

  # return in order of increasing edit length
  # FIXME: Should have a "standard" sort function
  return ( sort {    ( $a->loc->len             <=> $b->loc->len )
				  or ( $a->ref !~ m/^NM_/ and $b->ref =~ m/^NM_/)
				  or ( $a->loc->start->position <=> $b->loc->start->position )
				  or ( $a->post                 cmp $b->post )
				} @rv);
}


my %tx_cache;
sub _fetch_tx {
  my ($self,$id) = @_;
  #my $logger = Log::Log4perl->get_logger();
  if (not exists $tx_cache{$id}) {
	#warn("transcript cache MISS for $id");
	if ( $id =~ m/^ENS/ ) { 
	  @{$tx_cache{$id}} = $self->ens_conn->{ta}->fetch_by_stable_id($id);
	} else {
	  @{$tx_cache{$id}} = @{ $self->ens_conn->{ta}->fetch_all_by_external_name($id) };
	}
  } else {
	#warn("transcript cache HIT for $id");
  }
  return @{$tx_cache{$id}};
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
no Moose;
 __PACKAGE__->meta->make_immutable;
1;
