package Bio::HGVS::WebTranslator;
use base 'CGI';

use Bio::HGVS;

use File::Basename qw(basename);
use Template;
use TryCatch;

use Bio::HGVS::EnsemblConnection;
use Bio::HGVS::Errors;
use Bio::HGVS::Parser;
use Bio::HGVS::Translator;
#use Bio::HGVS::utils qw(fetch_hg_info);

our %info = (
  hg => { error => 'not available' },  #fetch_hg_info()
  jemappelle => basename( $0 ),
 );

sub process_request {
  my ($self) = @_;
  my %template_opts = ();

  my $ens = Bio::HGVS::EnsemblConnection->new();
  my $bhp = Bio::HGVS::Parser->new();
  my $bht = Bio::HGVS::Translator->new( $ens );

  my $q = CGI->new;
  my @variants = split(' ',$q->param('variants'));
  my @results = map { translate1($bhp,$bht,$_) } @variants;

  my $tt = Template->new(\%template_opts)
	|| die(Template->error());
  my $template = join('',<DATA>);

  $tt->process(\$template, {
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
	  @{$rv{c}} = $bht->convert_chr_to_cds(@{$rv{g}});
	  @{$rv{p}} = $bht->convert_cds_to_pro(@{$rv{c}});
	} elsif ($v->type eq 'c') {
	  @{$rv{c}} = ($v);
	  @{$rv{g}} = $bht->convert_cds_to_chr(@{$rv{c}});
	  @{$rv{p}} = $bht->convert_cds_to_pro(@{$rv{c}});
	} elsif ($v->type eq 'p') {
	  @{$rv{p}} = ($v);
	  @{$rv{c}} = $bht->convert_pro_to_cds(@{$rv{p}});
	  @{$rv{g}} = $bht->convert_cds_to_chr(@{$rv{c}});
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
 border-top: thin solid gray;
 background: #129;
 color: white;
 margin: 10px 0px 3px 0px;
 padding-left: 1px;
}
table.results {
 width: 100%;
 border: thin solid gray;
}
table.results tr {
 border-top: thin solid gray;
}
table.results tr:hover {
 background: #ccc;
}
table.results tr:hover td {
 background: inherit;
}
table.results th {
 background: #bbb;
 width: 33%;
}
table.results td.query {
 background: #cfc;
}
table.results tr.error {
 background: #fcc;
}
span.query {
 background: #cfc;
}
span.error {
 background: #fcc;
}
div.footer {
 color: #999;
 background: #ddd;
 border-top: thin solid #999;
 font-size: smaller;
 margin-top: 10px;
}
    </style>
  </head>

  <body>
  <h1>Locus &raquo; [% title %]</h1>

  Interconvert chromosomal, cDNA, and protein variants specified according
  to <a href="http://www.hgvs.org/mutnomen/">HGVS nomenclature for
  sequence variants</a>.

  <h2>Input</h2>
  <form action="" method="post">
  <table>
    <tr style="vertical-align:top">
      <td style"width:20%">Enter HGVS variants:
      <br><span style="color:gray; font-size:smaller">Multiple variants
      okay, separated by whitespace</span>
      </td>

      <td><textarea name="variants" rows=3 cols=40
      required="required" placeholder="e.g., NM_003227.3:c.2137A>T">
      </textarea>
      </td>

      <td><input type="submit" name="submit" value="Translate"/></td>
    </tr>
  </table
  </form>

[% IF results.size > 0 %]
  <h2>Results ([% results.size %])</h2>
  <b>Legend:</b> <span class="query">Input variant</span> | <span class="error">Error</span>
  <table class="results">
    <thead>
      <tr>
        <th>g.</th>
        <th>c.</th>
        <th>p.</th>
      </tr>
    </thead>

    <tbody>
[% FOREACH r IN results %]
  <tr>
[% IF r.error %]
  <tr class="error"><td colspan=3 class="error">[% r.error %]</td></tr>
[% ELSE %]
  <tr>
[% IF r.query_type == 'g' %]
	<td class="query">[% r.g.join('<br>') %]</td>
	<td              >[% r.c.join('<br>') %]</td>
	<td              >[% r.p.join('<br>') %]</td>
[% ELSIF r.query_type == 'c' %]
	<td              >[% r.g.join('<br>') %]</td>
	<td class="query">[% r.c.join('<br>') %]</td>
	<td              >[% r.p.join('<br>') %]</td>
[% ELSIF r.query_type == 'p' %]
	<td              >[% r.g.join('<br>') %]</td>
	<td              >[% r.c.join('<br>') %]</td>
	<td class="query">[% r.p.join('<br>') %]</td>
[% END %]
  </tr>
[% END %]
[% END %]
    </tbody>
  </table>
[% END %]


<div class="footer">
version: [% info.hg.tag %] (changeset: [% info.hg.changeset %]; date: [% info.hg.date %])
</div>
