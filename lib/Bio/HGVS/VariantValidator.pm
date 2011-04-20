package Bio::HGVS::VariantValidator;

use strict;
use warnings;

1;



__END__

This package will /semantically/ validate Bio::HGVS::Variant
instances.  Syntax validation is left to parsers that created the objects.

Tests to consider:

- pre seq = reference
- pre seq len = end-start+1
- pre seq != post seq?
- alphabet appropriate for moltype c,g,m,r,p
- ref seq appropriate for moltype c,g,m,r,p
- start < end
- intronic base position at intron boundary
