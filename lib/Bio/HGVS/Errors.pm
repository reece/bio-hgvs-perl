package Bio::HGVS::Errors;
use base qw(Exporter);

# The following code causes 'use Bio::HGVS::Errors' to export the
# throw/try/catch/except/otherwise/finally sugar from Error by default.
# 2011-04-10: Error.pm is deprecated, which is a shame.  We'll have
# to work around this eventually.
use Error qw(:try);
@EXPORT = @Error::subs::EXPORT_OK;
@EXPORT_OK = qw( errors );

use Bio::HGVS::Error;

our @errors =
  qw(
	  NotImplemented
	  Syntax
	  Type
   );

foreach my $error (@errors) {
  eval <<__EOEVAL__;
package Bio::HGVS::${error}Error;
use base qw(Bio::HGVS::Error);
__EOEVAL__
}

1;
