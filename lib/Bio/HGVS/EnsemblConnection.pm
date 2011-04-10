package Bio::HGVS::EnsemblConnection;

use strict;
use warnings;

use Carp::Assert;

use Bio::EnsEMBL::Registry;

use Bio::HGVS::Errors;

my %connection_info = (
  localhost => {
	host => 'localhost',
	port => 3306,
	user => 'anonymous',
  },

  ensembl => {
	host => 'ensembldb.ensembl.org',
	port => 5306,
	user => 'anonymous',
  },

  locus_remote => {
	host => 'outcast.locusdev.net',
	port => 3306,
	user => $ENV{MYSQL_USER},
	pass => $ENV{MYSQL_PWD},
  }
);

my $ens_conn = $ENV{ENS_CONN} || 'localhost';

our %defaults = (
  registry => 'Bio::EnsEMBL::Registry',
  %{$connection_info{$ens_conn}}
);


use Class::MethodMaker
  [
	scalar => [qw/ registry host user pass port /] ,
  ];


sub new {
  my ($class,%opts) = @_;
  my %self = (%defaults,%opts);
  my $self = bless(\%self,$class);
  $self->connect()->init_adaptors();
  return $self;
}

sub connect {
  my ($self) = @_;
  $self->registry->load_registry_from_db(
	-host => $self->host,
	-user => $self->user,
	-port => $self->port,
	-pass => $self->pass
   );
  $self->init_adaptors();
  return $self;
}

sub init_adaptors {
  my ($self) = @_;
  $self->{sa} = $self->registry->get_adaptor( 'Human', 'Core', 'Slice' );
  $self->{ta} = $self->registry->get_adaptor( 'Human', 'Core', 'Transcript' );
  $self->{va} = $self->registry->get_adaptor( 'Human', 'Variation', 'Variation' );
  $self->{vfa} = $self->registry->get_adaptor( 'Human', 'Variation', 'VariationFeature' );
}

1;
