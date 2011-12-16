package Bio::HGVS;


use Cwd 'abs_path';
use File::Basename qw(dirname);

# "extra" packages, if any, are in <installation root>/ext/
our $ROOT;
BEGIN {
  $ROOT = dirname(dirname(dirname(abs_path(__FILE__))));
}

use lib  "$ROOT/ext/lib/perl5";

1;
