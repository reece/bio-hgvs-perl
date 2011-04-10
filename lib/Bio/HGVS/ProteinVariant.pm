package Bio::HGVS::ProteinVariant;

use strict;
use warnings;

use Carp::Assert;

use Bio::HGVS::Errors;

use base 'Bio::HGVS::Variant';

sub new {
  my $type = shift;
  my $self = __PACKAGE__->SUPER::new(@_);
  $self->moltype('p');
  return $self;
}

sub var {
  my ($self) = @_;
  sprintf("%s%s%s",$self->pre,$self->pos,$self->post);
}

sub get_CDSVariants {
  my ($self) = @_;
  throw Bio::HGVS::NotImplementedError();
}
