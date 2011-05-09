#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../lib";
use Bio::HGVS::WebTranslator;
use Log::Log4perl;


eval {
  Bio::HGVS::WebTranslator->new()->process_request();
};

if ($@) {
  print error_page($@);
};

exit;

############################################################################

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

<div style="background:#ddd; border: thin solid #999; margin:20px; padding:5px; font-family:monospace; font-size: smaller;">
$@
</div>
</body>
</html>
EOF
}
