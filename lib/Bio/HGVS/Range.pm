package Bio::HGVS::Range;
use base Bio::HGVS::Location;

use Bio::HGVS::Errors;
use Bio::HGVS::Position;

use Mouse;									# after Bio::HGVS::Errors!
has 'start' => ( is => 'rw', isa => 'Bio::HGVS::Position' );
has 'end'   => ( is => 'rw', isa => 'Bio::HGVS::Position' );
no Moose;
__PACKAGE__->meta->make_immutable;

use strict;
use warnings;

use overload
  '""' => \&stringify,
  '==' => \&eq,
  '!=' => \&ne,
  'eq' => \&eq,
  'ne' => \&ne,
  ;

sub is_simple {
  my ($self) = @_;
  return $self->start->is_simple and $self->end->is_simple;
}

sub len {
  my ($self) = @_;
  if (not $self->is_simple) {
	# TODO: Implement len for non-simple ranges.
	throw Bio::HGVS::NotImplementedError('Can only compute lengths for "simple" ranges');
  }
  if (not defined $self->end) {
	return 1;
  }
  return $self->end->position - $self->start->position + 1;
}

sub stringify {
  my ($self) = @_;

  (defined $self->start)
	|| throw Bio::HGVS::Error("Range doesn't have a start!");

  if (    (not defined $self->end)
	   or ($self->start eq $self->end) ) {
	return $self->start;
  }

  return $self->start . '_' . $self->end;
}

sub eq {
  my ($a,$b) = @_;
  return ( 
	    ( $a->start eq $b->start)
	and ( $a->end eq $b->end )
   );
}

sub ne {
  my ($a,$b) = @_;
  return ( 
	    ( $a->start ne $b->start)
	or  ( $a->end ne $b->end )
   );
}

############################################################################
1;
