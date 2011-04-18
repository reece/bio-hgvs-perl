package Bio::HGVS::utils;

use base 'Exporter';
our @EXPORT_OK = qw(aa1to3 aa3to1 aa3 aa3_re string_diff);


my %AA3to1 = (
  'Ala' => 'A', 'Asx' => 'B', 'Cys' => 'C', 'Asp' => 'D',
  'Glu' => 'E', 'Phe' => 'F', 'Gly' => 'G', 'His' => 'H',
  'Ile' => 'I', 'Lys' => 'K', 'Leu' => 'L', 'Met' => 'M',
  'Asn' => 'N', 'Pro' => 'P', 'Gln' => 'Q', 'Arg' => 'R',
  'Ser' => 'S', 'Thr' => 'T', 'Val' => 'V', 'Trp' => 'W',
  'Xaa' => 'X', 'Tyr' => 'Y', 'Glx' => 'Z', 'Ter' => '*',
  'Sel' => 'U'
 );
my %AA1to3 = map { $AA3to1{$_} => $_ } keys %AA3to1;

my @aa3 = sort keys %AA3to1;
my @aa1 = sort keys %AA1to3;

my $aa3_re = join('|',@aa3);
$aa3_re = qr/$aa3_re/;

sub aa1to3 {
  join('', map {$AA1to3{$_}||'???'} $_[0] =~ m/(.)/g);
}

sub aa3to1 {
  join('', map {$AA3to1{$_}||'?'} $_[0] =~ m/(...)/g);
}

sub string_diff {
  my ($a,$b) = @_;
  if (length($a) != length($b)) {
	warn("WARNING: diffing strings of unequal length\n");
  }

  # after http://www.perlmonks.org/?node_id=882590
  my $diff = $a ^ $b;
  my @diffs;
  push(@diffs,{pos=>$-[1],len=>$+[1]-$-[1]}) while $diff =~ m/([^\x00]+)/xmsg;
  (my $mask = $diff) =~ tr{\x00}{\xff}c;

  return { diff => $diff,
		   mask => $mask,
		   diffs => \@diffs,
		   a_delta => $a & $mask,
		   b_delta => $b & $mask };
}

  

1;

