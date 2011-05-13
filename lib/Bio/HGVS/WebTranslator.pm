package Bio::HGVS::WebTranslator;
use base 'CGI';

use strict;
use warnings;

use Bio::HGVS;

use File::Basename qw(basename);
use File::Spec;
use Template;
use TryCatch;
use URI::Escape;

use Bio::HGVS::EnsemblConnection;
use Bio::HGVS::Errors;
use Bio::HGVS::Parser;
use Bio::HGVS::Translator;
use Bio::HGVS::utils qw(fetch_hg_info);

our %info = (
  hg => { fetch_hg_info() },
  jemappelle => basename( $0 ),
  ensembl_version => Bio::HGVS::EnsemblConnection->api_version()
 );

my %conn_info = %Bio::HGVS::EnsemblConnection::defaults;
sub process_request {
  my ($self) = @_;
  my %template_opts = (
	PLUGIN_BASE => 'Bio::HGVS::Template::Plugin',
	INCLUDE_PATH => File::Spec->catfile($Bio::HGVS::ROOT,'templates'),
	COMPILE_DIR => undef,
	TRIM => 1,
#	PRE_CHOMP => 1,
#	POST_CHOMP => 3,
   );

  my $ens = Bio::HGVS::EnsemblConnection->new(%conn_info);
  my $bhp = Bio::HGVS::Parser->new();
  my $bht = Bio::HGVS::Translator->new( ens_conn => $ens );

  my $q = CGI->new;
  my @variants;
  my @results;
  my $resultslink;
  if ($q->param('variants')) {
	@variants = split(/[,\s]+/,$q->param('variants'));
	@results = map { translate1($bhp,$bht,$_) } @variants;
	$resultslink = $q->url(-full=>1) . '?variants=' . uri_escape(join(',',@variants));
	warn("$resultslink");
  }

  my $tt = Template->new(\%template_opts)
	|| die(Template->error());

  my $template = 'bio-hgvs-webtranslator.html.tt2';
  my $rv = "Content-type: text/html\n\n";
  $tt->process(
	$template,
	{
	  variants => \@variants,
	  results => \@results,
	  info => \%info,
	  title => 'HGVS Translator',
	  resultslink => $resultslink
	},
	\$rv
   ) || die(Template->error());
  print $rv;
}

sub translate1 {
  my ($bhp,$bht,$hgvs) = @_;
  my %rv = (
	query => $hgvs,
	error => undef,
   );

  my $v;
  try {
	$v = $bhp->parse($hgvs);
	$rv{query_type} = $v->type;
	if ($v->type eq 'g') {
	  @{$rv{g}} = ($v);
	  try {
		@{$rv{c}} = $bht->convert_chr_to_cds(@{$rv{g}});
	  } catch (Bio::HGVS::Error $e) {
		@{$rv{c}} = $e;
	  };
	  try {
		@{$rv{p}} = $bht->convert_cds_to_pro(@{$rv{c}});
	  } catch (Bio::HGVS::Error $e) {
		@{$rv{p}} = $e;
	  };
	} elsif ($v->type eq 'c') {
	  @{$rv{c}} = ($v);
	  try {
		@{$rv{g}} = $bht->convert_cds_to_chr(@{$rv{c}});
	  } catch (Bio::HGVS::Error $e) {
		@{$rv{g}} = $e;
	  };
	  try {
		@{$rv{p}} = $bht->convert_cds_to_pro(@{$rv{c}});
	  } catch (Bio::HGVS::Error $e) {
		@{$rv{p}} = $e;
	  };
	} elsif ($v->type eq 'p') {
	  @{$rv{p}} = ($v);
	  try {
		@{$rv{c}} = $bht->convert_pro_to_cds(@{$rv{p}});
	  } catch (Bio::HGVS::Error $e) {
		@{$rv{c}} = $e;
	  };
	  try {
		@{$rv{g}} = $bht->convert_cds_to_chr(@{$rv{c}});
	  } catch (Bio::HGVS::Error $e) {
		@{$rv{g}} = $e;
	  };
	}
  } catch (Bio::HGVS::Error $e) {
	$rv{error} = $e;
  };
  return \%rv;
}


1;
