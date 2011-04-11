#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use FindBin;
use lib "$FindBin::RealBin/../lib";
use Bio::HGVS::Errors;

plan tests => $#Bio::HGVS::Errors::errors + 1;

sub thrower {
  my $fqe = shift;
  throw $fqe->new( 'text exception' );
}

foreach my $e (@Bio::HGVS::Errors::errors) {
  my $fqe = "Bio::HGVS::${e}Error";
  throws_ok {thrower($fqe)} $fqe ;
}
