package Bio::HGVS::VariantCoordinate;

use strict;
use warnings;

use Bio::HGVS::Errors;
use Data::Dumper;

use Class::MethodMaker
  [
	scalar => [qw/ start end /] ,
	scalar => [ +{-default=>0}, 'offset'],
	scalar => [ +{-default=>'_', -static=>1}, 'range_delim'],
   ];


use overload
  '""' => \&_stringify;


sub new {
  my ($class) = shift;
  my %self = @_;
  bless \%self,$class;
}

sub len {
  my ($self) = @_;
  return $self->end - $self->start + 1;
}

sub _stringify {
  my ($self) = @_;

  (defined $self->start)
	|| throw Bio::HGVS::Error("Range doesn't have a start!");

  if (defined $self->end and $self->start != $self->end) {
	(defined $self->offset) 
	  && throw Bio::HGVS::Error("Range with start!=end also has offset");
	return sprintf('%s%s%s', $self->start, $self->range_delim, $self->end);
  }

  if (defined $self->offset) {
	return sprintf('%s%+d', $self->start, $self->offset);
  }

  return $self->start;
}

############################################################################
1;
