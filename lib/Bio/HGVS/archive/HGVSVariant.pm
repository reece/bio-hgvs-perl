package Bio::HGVS::HGVSVariant;

use strict;
use warnings;

use Bio::HGVS::Errors;
#use Error qw(:try);

use overload
  '""' => \&stringify;

use Class::MethodMaker
  [ scalar => [qw/ ref moltype pos var /] ,
	new => [qw/ new /]
  ];

sub stringify {
  my $self = shift;
  sprintf('%s:%s.%s%s',
		  $self->ref,
		  $self->moltype,
		  $self->pos,
		  $self->var
		 );
}

sub parse_hgvs {
  # Ideally, this function would use a proper grammar to represent the
  # HGVS specification as much as possible.  For now, it's a simple regexp.
  # Regexp::Grammars is likely the right way to go.
  my ($self,$hgvs) = @_;
  my ($ref,$moltype,$pos,$var);
  try {
	($ref,$moltype,$pos,$var) = $hgvs =~ m/^([^:]+):([cgmpr])\.([*-+_\d]+)(.*)/
	  or throw GenomeCommons::HGVSSyntaxError('regexp did not match variant')
  };
  $self->ref($ref);
  $self->moltype($moltype);
  $self->pos($pos);
  $self->var($var);
  return $self;
}


1;
