package Bio::HGVS::Position;
use base Bio::HGVS::Location;

use strict;
use warnings;

use Bio::HGVS::Errors;


use Mouse;									# after Bio::HGVS::Errors!
has 'position' 		=> ( is => 'rw' );
has 'intron_offset' => ( is => 'rw', default => 0 );
no Moose;
__PACKAGE__->meta->make_immutable;


use overload 
  '""' => \&stringify,
  '==' => \&eq,
  '!=' => \&ne,
  'eq' => \&eq,
  'ne' => \&ne,
  ;

sub easy_new {
  my ($class) = shift;
  return $class->new( position => shift, offset => shift||0 );
}

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

sub eq {
  my ($a,$b) = @_;
  return ( ($a->position eq $b->position) 
			 and ($a->intron_offset eq $b->intron_offset) );
}

sub ne {
  my ($a,$b) = @_;
  return ( ($a->position ne $b->position) 
			 or ($a->intron_offset ne $b->intron_offset) );
}

############################################################################
1;
