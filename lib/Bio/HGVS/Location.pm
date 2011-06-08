package Bio::HGVS::Location;

use Bio::HGVS::Errors;

sub is_simple {
  Bio::HGVS::NotImplemented->throw('Subclass must override this method');
}

sub len {
  Bio::HGVS::NotImplemented->throw('Subclass must override this method');
}

sub new {
  my ($class,%self) = @_;
  bless( \%self, $class );
}

############################################################################
1;
