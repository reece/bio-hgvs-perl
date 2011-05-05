package Bio::HGVS::CDSVariant;

use strict;
use warnings;

use Carp::Assert;

use Bio::HGVS::Errors;

use base 'Bio::HGVS::Variant';

sub new {
  my $type = shift;
  my $self = __PACKAGE__->SUPER::new(@_);
  $self->moltype('c');
  return $self;
}

sub get_GenomicVariants {
  my ($self) = @_;
}

sub get_ProteinVariants {
  my ($self) = @_;
}
