package Bio::HGVS::Location;

use Bio::HGVS::Errors;

sub is_simple {
  throw Bio::HGVS::NotImplemented('Subclass must override this method');
}

sub len {
  throw Bio::HGVS::NotImplemented('Subclass must override this method');
}

sub new {
  my ($class,%self) = @_;
  bless( \%self, $class );
}

############################################################################
1;
