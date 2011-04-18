=head1 NAME

  Bio::HGVS::LocationMapper -- map corresponding chromosomal, coding RNA, and
  protein sequence coordinates using HGVS extensions

=head1 SYNOPSIS

  use Bio::HGVS::LocationMapper;
  my $cm = Bio::HGVS::LocationMapper->new( transcript => ... );
  $cm->gen_to_

=head1 DESCRIPTION

Bio::HGVS::LocationMapper is thin wrapper around
Bio::EnsEMBL::Transcript that relates chromosomal, coding RNA, and protein
sequence coordinates.  This class "understands" simple position and ranges
(e.g., 22 or 55_72) as well as HGVS intron and UTR positions and ranges
(e.g., -34+6, *22, or -15+2_-15+8), as represented in Bio::HGVS::Location
objects.

Sequence variants may be described in chromosomal, genomic, CDS, and
protein.  For the purposes of this class, "chromosomal variants" means
specifically genomic variants with a chromosomal reference seqeuence.

Notes:
- transcript centric. Transcript occurs in one place on the genome and has
  zero or one translation.

=cut

package Bio::HGVS::LocationMapper;

use Data::Dumper;
use Carp::Assert;

use Bio::HGVS::Error;
use Bio::HGVS::Location;
use Bio::EnsEMBL::Transcript;

use Mouse;
has 'transcript' => (
  is => 'rw',
  isa => 'Bio::EnsEMBL::Transcript'
 );


sub chr_to_gen {
  my ($self,$l) = @_;
  throw Bio::HGVS::NotImplementedError('Not yet implemented');
}

sub gen_to_chr {
  my ($self,$l) = @_;
  throw Bio::HGVS::NotImplementedError('Not yet implemented');
}

sub chr_to_cds {
  my ($self,$l) = @_;
  my $tx = $self->transcript->transform('chromosome');

  if (not defined $tx->cdna_coding_start) {
	# TODO: Consider whether to handle variants in non-coding
	# transcripts
	return;
	#throw Bio::HGVS::NotImplementedError(
	#  "Transcript doesn't have cdna_coding_start"
	# );
  }

  my ($coord) = $tx->genomic2cdna($l->start->position,
								  $l->end->position,
								  1);

  # FIXME: Need to construct an intron-offset variant in the cdna
  # The following test is intended to detect whether a genomic position
  # is within a UTR or intron.  Rethink this test
  if (not exists $coord->{id}) {
	#warn("$hgvs_g isn't a coding variant") unless $warned++;
	return;
  }

  assert( defined $coord->start, 'start not defined' );
  assert( defined $coord->end, 'end not defined' );
  assert( defined $tx->cdna_coding_start, 'cdna_coding_start not defined' );

  return Bio::HGVS::Range->easy_new(
	$coord->start - ($tx->cdna_coding_start-1), undef,
	$coord->end   - ($tx->cdna_coding_start-1), undef
   );
}

sub cds_to_chr {
  my ($self,$l) = @_;
  my $tx = $self->transcript;
  assert(defined $tx->cdna_coding_start,
		 '$tx->cdna_coding_start undefined!');
  my ($coord) = $tx->cdna2genomic(
	$tx->cdna_coding_start + $l->start->position - 1,
	$tx->cdna_coding_start + $l->end->position   - 1,
   );

  return Bio::HGVS::Range->easy_new($coord->start + $tx->strand*$l->start->intron_offset, undef,
									$coord->end   + $tx->strand*$l->end->intron_offset,   undef),

}

sub cds_to_pro {
  my ($self,$l) = @_;
  if (not $l->is_simple) {
	throw Bio::HGVS::Error('variant is in intron or UTR region');
  }
  my $ploc = Bio::HGVS::Range->easy_new(
	int( ($l->start->position - 1)/3 ) + 1, undef,
	int( ($l->end->position   - 1)/3 ) + 1, undef
   );
  return $ploc;
}

sub pro_to_cds {
  my ($self,$l) = @_;
  return Bio::HGVS::Range->easy_new(
	3 * $l->start->position - 2, undef,
	3 * $l->end->position, undef
   );
}


#This mapper provides simplified low-level coordinate translation based
#solely on the genomic/cds structure of the region.  That is, this class
#specifically avoids dependencies on the origin of the sequence
#information, such as NCBI or Ensembl.

############################################################################
no Moose;
 __PACKAGE__->meta->make_immutable;
1;
