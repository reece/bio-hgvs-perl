package Bio::HGVS::EnsemblConnection;

use strict;
use warnings;

use Carp::Assert;

use Bio::HGVS;
use Bio::HGVS::Errors;

use Bio::EnsEMBL::ApiVersion;
use Bio::EnsEMBL::Registry;


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

sub api_version {
  my ($self) = @_;
  return software_version();
}

sub init_adaptors {
  my ($self) = @_;
  my @adaptors = (
	[ qw(sa Human Core Slice) ],
	[ qw(ta Human Core Transcript) ],
	[ qw(va Human Variation Variation) ],
	[ qw(vfa Human Variation VariationFeature) ],
   );

  foreach my $a (@adaptors) {
	my ($abbr,@def) = @$a;
	$self->{$abbr} = $self->registry->get_adaptor(@def);
	if (not defined $self->{$abbr}) {
	  Bio::HGVS::Error->throw(
		error => sprintf("Couldn't defined %s adaptor (%s,%s,%s)",
						 $abbr,@def));
	}
  }
}

1;
