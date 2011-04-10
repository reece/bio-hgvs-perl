package Bio::HGVS::Errors;
# The following code causes 'use Bio::HGVS::Errors' to export
# the throw/try/catch/except/otherwise/finally sugar by default.
use base qw(Exporter);
use Error qw(:try);
@EXPORT = @Error::subs::EXPORT_OK;


package Bio::HGVS::Error;
use base qw(Bio::Unison::Exception);

sub xmlify($) {
  my $self = shift;
  my $r = '<Error>';
  $r .= sprintf('<Type>%s</Type>', ref($self)||$self);
  $r .= sprintf('<Message>%s</Message>', $self->error());
  $r .= sprintf('<Detail>%s</Detail>', $self->detail()) if defined $self->detail();
  $r .= sprintf('<Advice>%s</Advice>', $self->advice()) if defined $self->advice();
  $r .= sprintf('<Stacktrack>%s</Stacktrace>', $self->stacktrace());
  $r .= '</Error>';
  return $r;
}




foreach my $error (qw(Syntax NotImplemented)) {
  my $b = <<EOF;
package Bio::HGVS::${error}Error;
use base qw(Bio::HGVS::Error);
EOF
  eval $b;
}

1;
