package Bio::HGVS::EnsemblConnection;

use strict;
use warnings;

use Carp::Assert;
use TryCatch;

use Bio::HGVS;
use Bio::HGVS::Errors;

use Bio::EnsEMBL::ApiVersion;
use Bio::EnsEMBL::Registry;


my %connection_info = (
  localhost => {
	host => 'ensembl-vpn.locusdev.net',
	port => 3306,
	user => 'anonymous',
  },

  ensembl_public => {
	host => 'ensembldb.ensembl.org',
	port => 5306,
	user => 'anonymous',
	pass => undef
  },

  locus_remote => {
	host => 'ensembl-vpn.locusdev.net',
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


use Moose;
has 'registry' => ( is => 'ro' );
has 'host'     => ( is => 'ro' );
has 'user'     => ( is => 'ro' );
has 'pass'     => ( is => 'ro' );
has 'port'     => ( is => 'ro' );


sub BUILD {
  my $self = shift;
  $self->{$_} = $defaults{$_} for grep {not defined $self->{$_}} keys %defaults;
  $self->connect();
  $self->init_adaptors();
  return $self;
}

sub disconnect_all {
  my $self = shift;
  $self->registry->disconnect_all();
}

sub connect {
  my ($self) = @_;

  try {
	$self->registry->load_registry_from_db(
	  -host => $self->host,
	  -user => $self->user,
	  -port => $self->port,
	  -pass => $self->pass
	 )
  } catch {
	Bio::HGVS::ConnectionError->throw(
	  sprintf('Connection to EnsEMBL %s:%s@%s:%s failed',
			  $self->{user},
			  (defined $self->{pass} ? '<pass>' : '<nopass>'),
			  $self->{host},
			  $self->{port}));
  };

  return $self;
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

sub api_version {
  my ($self) = @_;
  return software_version();
}



no Moose;
 __PACKAGE__->meta->make_immutable;
1;
