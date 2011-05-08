#!/usr/bin/perl

use strict;
use warnings;

use CGI;
use File::Basename;
use FindBin;
use IO::Pipe;

#use URI::Escape;
#use lib "$FindBin::RealBin/../ext/lib/perl5";
#use TryCatch;

# Anything that might fail, including loading of modules that aren't in
# the standard Perl package (as of 5.10), is wrapped in an eval so that a
# meaningful error can be delivered to the web page.
eval {
  use lib "$FindBin::RealBin/../ext/lib/perl5";
  use Template;
  use TryCatch;

  use lib "$FindBin::RealBin/../lib";
  use Bio::HGVS::EnsemblConnection;
  use Bio::HGVS::Errors;
  use Bio::HGVS::Parser;
  use Bio::HGVS::Translator;

  my %info = (
	hg => { fetch_hg_info() },
	jemappelle => basename( $0 )
  );

  handle_request(\%info);
};

if ($@) {
  print error_page($@);
};


exit;

############################################################################

sub handle_request {
  my ($info) = @_;
  my %template_opts = ();

  my $ens = Bio::HGVS::EnsemblConnection->new();
  my $bhp = Bio::HGVS::Parser->new();
  my $bht = Bio::HGVS::Translator->new( $ens );

  my $q = CGI->new;
  my @variants = $q->param('variants');
  my @results = map { translate1($bhp,$bht,$_) } @variants;

  my $tt = Template->new(\%template_opts)
	|| die(Template->error());
  my $template = join('',<DATA>);
  return $tt->process(\$template, {
	variants => \@variants,
	results => \@results,
	info => $info,
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
  } catch (Bio::HGVS::Error $e) {
	$rv{error} = $e;
	return \%rv;
  };

  $rv{query_type} = $v->type;
  if ($v->type eq 'g') {
	$rv{g} = [$hgvs];
	$rv{c} = ['g->c'];
	$rv{p} = ['g->c->p'];
  } elsif ($v->type eq 'c') {
	$rv{c} = [$hgvs];
	$rv{g} = ['c->g'];
	$rv{p} = ['c->p'];
  } elsif ($v->type eq 'p') {
	$rv{p} = [$hgvs];
	$rv{c} = ['p->c'];
	$rv{g} = ['p->c->g'];
  }

  return \%rv;
}


sub fetch_hg_info {
  my %rv;
  my $hg_in = IO::Pipe->new();
  if (not $hg_in->reader( qw(/usr/bin/hg log -l 1), $FindBin::RealBin )) {
	throw Bio::GenomeCommons::Error($!);
  }
  while ( my $line = <$hg_in> ) {
	if (my ($k,$v) = $line =~ m/^(\w+):\s+(.+)/) {
	  $rv{$k} = $v;
	}
  }
  $rv{'changeset'} =~ s/^\d+://;
  return %rv;
}

sub error_page {
  return <<EOF;
Content-type: text/html

<html>
<head>
  <title>An Error occurred</title>
</head>

<body>
<h1>An error occurred.</h1>

Sorry, the following error occurred:

<div style="background:#ddd; margin:20px; padding:5px;"><pre>
$@
</pre></div>
</body>
</html>
EOF
}


__DATA__
@@ hgvstranslator.html.ep
<!doctype html>
<html>
  <head>
    <title>Locus &raquo; [% $title %]</title>
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
table.results th {
 background: #ddd;
 width: 33%;
}
table.results td.query {
 background: #cc2;
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

  <h1>Locus &raquo; [% $title %]</h1>

  Interconvert chromosomal, cDNA, and protein variants specified according
  to <a href="http://www.hgvs.org/mutnomen/">HGVS nomenclature for
  sequence variants</a>.

  <h2>Input</h2>
  <form method="post">
  <table>
    <tr style="vertical-align:top">
      <td style"width:20%">Enter HGVS variants:
      <br><span style="color:gray; font-size:smaller">Multiple variants
      okay, separated by whitespace</span>
      </td>

      <td><textarea name="hgvs-variants" rows=3 cols=40
      required="required" placeholder="e.g., NM_003227.3:c.2137A>T">
      </textarea>
      </td>

      <td><input type="submit" name="submit" value="Translate"/></td>
    </tr>
  </table
  </form>

[% IF results %] {
  <h2>Results ([% results.size %])</h2>
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
		<td class="query"></td>
		<td              ></td>
		<td              ></td>
	  </tr>
[% END %]
    </tbody>
  </table>
[% END %]


<div class="footer">
version: [% info.hg.tag %] (changeset: [% info.hg.changeset %]; date: [% info.hg.date %])
</div>

  </body>
</html>
