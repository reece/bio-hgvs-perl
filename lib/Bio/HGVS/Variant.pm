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
use Bio::HGVS::Location;

use overload
  '""' => \&stringify;

# Instance variables:
use Mouse;									# must be after B:GC:Errors!
has 'loc' 	=> ( is => 'rw', isa => 'Bio::HGVS::Location' );
has 'name' 	=> ( is => 'rw' );
has 'op' 	=> ( is => 'rw' );
has 'post' 	=> ( is => 'rw' );
has 'pre' 	=> ( is => 'rw' );
has 'ref'  	=> ( is => 'rw' );
has 'type' 	=> ( is => 'rw', required => 1 );
no Moose;
__PACKAGE__->meta->make_immutable;



=head1 METHODS

=cut

############################################################################

=head2 ->len()

returns the length of the change to the reference sequence.  For
insertions, the length is 0.

=cut

sub len {
  my ($self) = @_;
  return $self->loc->len;
}

sub var {
  my ($self) = @_;

  if ( (length($self->pre) == 0) and (length($self->post) != 0) ) {
	return sprintf('%sins%s', $self->loc, $self->post);
  }

  if ( (length($self->post) == 0) ) {
	# N.B. pre is optional for delete
	return sprintf('%sdel%s', $self->loc, $self->pre);
  }

  if ( length($self->pre) != length($self->post) ) {
	return sprintf('%sdelins%s', $self->loc, $self->post);
  }

  if ( length($self->pre) == length($self->post) ) {
	if ($self->type eq 'p') {
	  return sprintf('%s%s%s', $self->pre, $self->loc, $self->post),
	}
	return sprintf('%s%s>%s', $self->loc, $self->pre, $self->post);
  }

  throw Bio::HGVS::Error("Couldn't format variant");
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
