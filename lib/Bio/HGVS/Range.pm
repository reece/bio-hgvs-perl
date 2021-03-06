package Bio::HGVS::Range;
use base Bio::HGVS::Location;

use Bio::HGVS::Errors;
use Bio::HGVS::Position;

use Carp::Assert;

use Mouse;									# after Bio::HGVS::Errors!
has 'start' => ( is => 'rw', isa => 'Bio::HGVS::Position', required => 1 );
has 'end'   => ( is => 'rw', 
				 isa => 'Bio::HGVS::Position',
				 default => sub { $_[0]->start } # for single-position Ranges
				);

use overload
  '""' => \&stringify,
  '==' => \&eq,
  '!=' => \&ne,
  'eq' => \&eq,
  'ne' => \&ne,
  ;

sub easy_new {
  my ($class) = shift;
  my $self = Bio::HGVS::Range->new(
	start => Bio::HGVS::Position->easy_new(shift,shift)
   );
  if (@_ and defined $_[0]) {
	$self->end( Bio::HGVS::Position->easy_new(shift,shift) );
  }
  return $self;
}

sub is_simple {
  my ($self) = @_;
  return $self->start->is_simple and (not defined $self->end or $self->end->is_simple);
}

sub len {
  my ($self) = @_;
  if (not $self->is_simple) {
	# TODO: Implement len for non-simple ranges.
	Bio::HGVS::NotImplementedError->throw(
	  'Can only compute lengths for "simple" ranges');
  }
  if (not defined $self->end) {
	return 1;
  }
  return $self->end->position - $self->start->position + 1;
}

sub stringify {
  my ($self) = @_;

  (defined $self->start)
	|| Bio::HGVS::Error->throw("Range doesn't have a start!");

  if ( (defined $self->end)
	   and ($self->start ne $self->end)) {
	return $self->start . '_' . $self->end;
  }

  return $self->start;
}

sub eq {
  my ($a,$b) = @_;
  assert($a->isa('Bio::HGVS::Range'));
  assert($b->isa('Bio::HGVS::Range'));
  return ( 
	($a->start eq $b->start)
	  and
	( (not(defined $a->end) and not(defined $b->end))
		or ($a->end eq $b->end) )
   );
}

sub ne {
  my ($a,$b) = @_;
  return not $a->eq($b);
}

############################################################################
no Moose;
__PACKAGE__->meta->make_immutable;
1;
