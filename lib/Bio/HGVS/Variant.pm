=head1 NAME

  Bio::HGVS::Variant -- represent variants

=head1 SYNOPSIS

  use Bio::HGVS::Variant;
  my $variant = Bio::HGVS::Variant->new( ... );

=head1 DESCRIPTION

Bio::HGVS::Variant is a base class for the representation of
nucleic acid and amino acid sequence variations.

=cut


package Bio::HGVS::Variant;

use strict;
use warnings;

use Carp::Assert;
use Data::Dumper;

use Bio::HGVS::Errors;
use Bio::HGVS::VariantCoordinate;

use overload
  '""' => \&stringify;

# Instance variables:
use Mouse;									# must be after B:GC:Errors!
has 'end' 	=> ( is => 'rw' );
has 'intron_offset' => ( is => 'rw', default => 0 );
has 'name' 	=> ( is => 'rw' );
has 'op' 	=> ( is => 'rw' );
has 'post' 	=> ( is => 'rw' );
has 'pre' 	=> ( is => 'rw' );
has 'ref'  	=> ( is => 'rw' );
has 'start' => ( is => 'rw' );
has 'type' 	=> ( is => 'rw', required => 1 );


=head1 METHODS

=cut

############################################################################

=head2 ->len()

returns the length of the change to the reference sequence.  For
insertions, the length is 0.

=cut

sub len {
  my ($self) = @_;
  return $self->end - $self->start + 1;
}



############################################################################

=head2 ->pos()

returns the position of the variant as a simple position, range, or
intron-based coordinate

=cut

sub pos {
  my ($self) = @_;
  my $range_delim = '_';

  (defined $self->start)
	|| throw Bio::HGVS::Error("Range doesn't have a start!");

  if (defined $self->intron_offset and $self->intron_offset != 0) {
	return sprintf('%s%+d', $self->start, $self->intron_offset);
  }

  if (defined $self->end and $self->start != $self->end) {
	(defined $self->intron_offset and $self->intron_offset != 0) 
	return sprintf('%s%s%s', $self->start, $range_delim, $self->end);
  }

  return $self->start;
}

sub var {
  my ($self) = @_;
  if ($self->type eq 'p') {
	return sprintf('%s%s%s', $self->pre, $self->pos, $self->post),
  }
  return sprintf('%s%s>%s', $self->pos, $self->pre, $self->post);
}

sub stringify {
  my ($self) = @_;
  return sprintf('%s:%s.%s',
				 $self->ref,
				 $self->type,
				 $self->var
				);
}

=head1 BUGS and CAVEATS

=head1 SEE ALSO

=head2 Bio::HGVS::

Bio::HGVS::VariantParser,  Bio::HGVS::VariantFormatter

=head2 Other modules

Ensembl::Variation

=head2 Links

=over

=item mutnomen

=back

=head1 AUTHOR and LICENSE

=cut

1;
