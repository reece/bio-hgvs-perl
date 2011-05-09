package Bio::HGVS;

use Cwd 'abs_path';
use File::Basename qw(dirname);

BEGIN {
  our $E_BASE = '/locus/opt/ensembl';
  our $ROOT = dirname(dirname(dirname(abs_path(__FILE__))));
}

use lib  "$ROOT/ext/lib/perl5";

use lib map {"$E_BASE/$_"} (qw(
	bioperl-1.2.3
    61/bioperl-live
    61/ensembl/modules
    61/ensembl-variation/modules
  ));


1;
