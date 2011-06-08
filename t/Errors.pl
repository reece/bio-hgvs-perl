#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../lib";
use lib "$FindBin::RealBin/../ext/lib/perl5";

use Test::More;
use Test::Exception;
use TryCatch;

use Bio::HGVS::Errors;


my @classes = grep { m/^Bio::HGVS::/ } Exception::Class->Classes();

plan tests => ($#classes+1) + 1;


sub thrower {
  my $e = shift;
  $e->throw(error => "I'm a $e Exception");
}
foreach my $e (@classes) {
  throws_ok {thrower($e)} $e;
}


my $ec = 'Bio::HGVS::Error';
try {
  $ec->throw( error => "I'm a $ec exception",
			  detail => 'this is some detail',
			  advice => 'consider deoderant'
			 );
  die;
} catch (Bio::HGVS::Error $e) {
  diag $e->full_message_as_xml_string;
  pass( "I threw and caught a $e" )
} catch {
  fail( 'I missed the thrown exception!' );
};
