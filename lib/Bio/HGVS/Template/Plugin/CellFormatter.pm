package Bio::HGVS::Template::Plugin::CellFormatter;

use strict;
use warnings;
use base 'Template::Plugin';

use Bio::HGVS::Errors;

sub new {
    my ($class, $context) = @_;;
	return \&cell_formatter;
}

sub cell_formatter {
  return '' unless @_;

  if (not ref($_[0]) eq 'ARRAY') {
	Bio::HGVS::Error->throw('Expected 1 arg, an array ref');
  }

  my @v = @{$_[0]};
  if (ref($v[0]) and $v[0]->isa('Bio::HGVS::Error')) {
	chomp($v[0]);
	return '<div class="error">' . $v[0] . '</div>';
  }
  return join('<br>',@v);
}

1;


