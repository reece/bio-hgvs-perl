package Bio::HGVS::GenomicVariant;

use strict;
use warnings;

use Carp::Assert;

use Bio::HGVS::Errors;

use base 'Bio::HGVS::Variant';

sub new {
  my $type = shift;
  my $self = __PACKAGE__->SUPER::new(@_);
  $self->moltype('g');
  return $self;
}
