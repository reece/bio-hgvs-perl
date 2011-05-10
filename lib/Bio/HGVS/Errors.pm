package Bio::HGVS::Errors;

use Exception::Class (
  'Bio::HGVS::Error' => {
	description => 'A general error within the Bio::HGVS:: tools.',
	fields => [ 'detail', 'advice' ],
  },

  'Bio::HGVS::NotImplementedError' => {
	description => 'The routine or method is planned but not yet available.',
	isa => 'Bio::HGVS::Error',
  },

  'Bio::HGVS::SyntaxError' => {
	description => 'The provided data is improperly formatted.',
	isa => 'Bio::HGVS::Error',
  },

  'Bio::HGVS::TypeError' => {
	description => 'The provided data is not of the expected type.',
	isa => 'Bio::HGVS::Error',
  },
);


package Bio::HGVS::Error;
use XML::LibXML;

sub type {
  return ref $_[0];
}
sub as_string {
  my $self = shift;
  return $self->type 
	. (defined $self->error ? ': '.$self->error : '') 
	. "\n";
}
sub full_message {
  my $self = shift;
  my $rv = $self->as_string;
  $rv .= sprintf("Where:   package %s at %s:%s\n", 
				 $self->package, $self->file, $self->line);
  $rv .= 'Detail: ' . $self->detail . "\n" if defined $self->detail;
  $rv .= 'Advice: ' . $self->detail . "\n" if defined $self->advice;
  $rv .= $self->trace;
  return $rv;
}
sub toXML {
  my ($self) = shift;
  my $e = XML::LibXML::Element->new('error');
  $e->setAttribute('type',$self->type);
  $e->setAttribute('package',$self->package);
  $e->setAttribute('file',$self->file);
  $e->setAttribute('line',$self->line);
  $e->appendTextChild('error',  $self->error)   if defined $self->error;
  #$e->appendTextChild('message',$self->message) if defined $self->message;
  $e->appendTextChild('detail', $self->detail)  if defined $self->detail;
  $e->appendTextChild('advice', $self->advice)  if defined $self->advice;
  return $e;
}
sub full_message_as_xml {
  goto &toXML;
}
sub full_message_as_xml_string {
  $_[0]->full_message_as_xml->toString;
}


1;
