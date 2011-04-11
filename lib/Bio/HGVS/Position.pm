package Bio::HGVS::Position;
use base Bio::HGVS::Location;

use strict;
use warnings;

use Bio::HGVS::Errors;

use Mouse;									# after Bio::HGVS::Errors!
has 'position' => ( is => 'rw' );
has 'intron_offset' => ( is => 'rw', default => 0 );
no Moose;
__PACKAGE__->meta->make_immutable;


use overload '""' => \&stringify;

sub is_simple {
  my ($self) = @_;
  return (
	          $self->position =~ m/^[-+]?\d+$/
		  and $self->intron_offset == 0
		 );
}

sub len {
  return 1;
}

sub stringify {
  my ($self) = @_;
  return ( (defined $self->intron_offset and $self->intron_offset != 0)
			 ? sprintf('%s%+d', $self->position, $self->intron_offset)
			 : $self->position );
}

############################################################################
1;
