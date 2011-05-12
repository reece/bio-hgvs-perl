package Bio::HGVS;

use Cwd 'abs_path';
use File::Basename qw(dirname);

our $ROOT;
our $E_BASE;
BEGIN {
  $ROOT = dirname(dirname(dirname(abs_path(__FILE__))));
  $E_BASE = '/locus/opt/ensembl';
}

use lib  "$ROOT/ext/lib/perl5";

use lib map {"$E_BASE/$_"} (qw(
	bioperl-1.2.3
    61/bioperl-live
    61/ensembl/modules
    61/ensembl-variation/modules
  ));


1;
