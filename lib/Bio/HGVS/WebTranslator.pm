package Bio::HGVS::WebTranslator;
use base 'CGI';

use strict;
use warnings;

use Bio::HGVS;

use File::Basename qw(basename);
use File::Spec;
use Template;
use TryCatch;

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
  my @variants = split(/[,\s]+/,$q->param('variants'));
  my @results = map { translate1($bhp,$bht,$_) } @variants;

  my $tt = Template->new(\%template_opts)
	|| die(Template->error());

  #my $template = __PACKAGE__ . '.html.tt2';
  #my $template = 'bio-hgvs-webtranslator.html.tt2';
  $tt->process(\*DATA, {
	variants => \@variants,
	results => \@results,
	info => \%info,
	title => 'HGVS Translator',
  }) || die(Template->error());
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



__DATA__
Content-type: text/html

<!doctype html>
<html>
  <head>
    <title>Locus &raquo; [% title %]</title>
    <script language="javascript" src=
    'http://ajax.googleapis.com/ajax/libs/jquery/1.6/jquery.min.js'></script>
    <style type="text/css">

h1 {
 margin: 0px;
}
h2 {
 background: #036;
 color: white;
 margin: 10px 0px 3px 0px;
 padding-left: 1px;
}

table.results {
 width: 100%;
 border: thin solid gray;
 border-collapse: collapse;
}
table.results tr:hover {
 background: #aaa;
}
table.results th, table.results td {
 border: thin solid gray;
}
table.results th {
 background: #ddd;
 width: 33%;
}
/* deferred/experimental change
table.results td {
  font-family: monospace;
  font-size: smaller;
}
*/
table.results td.query {
 background: #cfc;
}

span.query {
 background: #cfc;
}
div.header {
 border-bottom: thin solid #999;
}
p.quote {
  border-left: thin dotted gray;
  margin-left: 2px;
  padding-left: 2px;
  font-style: italic;
  font-size: smaller;
  color: gray;
  float: right;
  width: 40%;
}
p.subtitle {
  margin: 0px;
  font-size:smaller;
  width:80%;
}
div.footer {
 color: #777;
 background: #ddd;
 border-top: thin solid #999;
 font-size: smaller;
 margin-top: 10px;
}
p.note {
 margin: 5px;
 color: red;
 font-size: smaller;
 padding: 1px;
 text-align: center;
}
.error {
  background: #fcc;
  font-size: smaller;
  font-style: italic;
}
    </style>
  </head>

  <body>

  <div class="header">
    <p class="quote" style="float:right;" title="exactly so when one
    finishes a Perl project">
    I had desired it with an ardour that far exceeded moderation; but now
    that I had finished, the beauty of the dream vanished, and breathless
    horror and disgust filled my heart.  -- Frankenstein, Mary Shelley
    </p>

    <h1>Locus &raquo; [% title %]</h1>
    <p class="subtitle"> Interconvert chromosomal, transcript, and protein
    variants specified according to <a
    href="http://www.hgvs.org/mutnomen/">HGVS nomenclature for sequence
    variants</a>.</p>
  </div>

  <p class="note">
  Note: This is a work-in-progress. Please see the list of <a target="_blank"
  href="https://bitbucket.org/reece/bio-hgvs-perl/issues?status=new&status=open&sort=milestone">
  bugs and planned features</a>. Please add any bugs or feature requests
  there.</p>

  <h2>Input</h2>
  <form action="" method="post">
  <table>
    <tr style="vertical-align:top">
      <td style"width:20%">Enter HGVS variants:
      <br><span style="color:gray; font-size:smaller">Multiple variants
      okay, separated by whitespace</span>
      </td>

      <td><textarea name="variants" rows=3 cols=40
      required="required" placeholder="e.g., NM_003227.3:c.2137A>T"/></textarea>
      </td>

      <td><input type="submit" name="submit" value="Translate"/></td>
    </tr>
  </table
  </form>

[%- IF results.size > 0 %]
[%- USE cell_formatter = CellFormatter %]
  <h2>Results ([% results.size %])</h2>
  <b>Legend:</b> <span class="query">Input variant</span> | <span class="error">Error</span>
  <table class="results">
    <thead>
      <tr>
        <th>genomic (g.)</th>
        <th>transcript (c., r.)</th>
        <th>protein (p.)</th>
      </tr>
    </thead>
    <tbody>
    [%- FOREACH r IN results %]
      <tr>
      [%- IF r.error %]
       <td colspan=3 class="error">[% r.error %]</td>
       [%- ELSE %]
       <td[% IF r.query_type == 'g' %] class="query"[% END %]>[% cell_formatter(r.g) %]</td>
       <td[% IF r.query_type == 'c' %] class="query"[% END %]>[% cell_formatter(r.c) %]</td>
       <td[% IF r.query_type == 'p' %] class="query"[% END %]>[% cell_formatter(r.p) %]</td>
       [%- END %] [%# error/not error %]
      </tr>
    [%- END %] [%# row loop %]
    </tbody>
  </table>
[%- END %] [%# if results %]


<div class="footer">
<div style="float:right">
<a target="_blank" href="https://bitbucket.org/reece/bio-hgvs-perl/">Code</a>
<span style="margin:0px 5px;">|</span>
<a target="_blank" href="https://bitbucket.org/reece/bio-hgvs-perl/issues?status=new&status=open&sort=milestone">Issue Tracker</a>
<span style="margin:0px 5px;">|</span>
<a target="_blank" href="https://bitbucket.org/reece/bio-hgvs-perl/changesets">Change Log</a>
</div>

Translator Version: [% info.hg.tag %] / [% info.hg.changeset %] / [% info.hg.date %]
<span style="margin:0px 5px;">|</span>
Data: <a target="_blank" href="http://www.ensembl.org">EnsEMBL</a> [% info.ensembl_version %]
</div>
