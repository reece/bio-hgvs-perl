package Bio::HGVS::utils;

use base 'Exporter';
our @EXPORT_OK = qw(aa1to3 aa3to1 aa3 aa3_re string_diff shrink_diff fetch_hg_info);

use FindBin;


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
  push(@diffs,{'pos'=>$-[1],'len'=>$+[1]-$-[1]}) 
	while $diff =~ m/([^\x00]+)/xmsg;
  (my $mask = $diff) =~ tr{\x00}{\xff}c;
  return { diff => $diff,
		   mask => $mask,
		   diffs => \@diffs,
		   a_delta => $a & $mask,
		   b_delta => $b & $mask };
}

sub shrink_diff {
  my ($a,$b) = @_;
  my $di = string_diff($a,$b);
  my @diffs = @{$di->{diffs}};
  return unless @diffs;
  # handle discontiguous diffs by taking the min,max pos
  my ($s,$e) = ($diffs[0]->{'pos'}, $diffs[$#$diffs]->{'pos'}+$diffs[$#$diffs]->{'len'}-1);
  return [$s,$e-$s+1];
}


my $hg_info;
sub fetch_hg_info {
  $hg_info = %{ _fetch_hg_info } unless defined $hg_info;
  return %$hg_info;
}
sub _fetch_hg_info {
  my $hg_in = IO::Pipe->new();
  if ($hg_in->reader( qw(/usr/bin/hg log -l 1), __FILE__ )) {
	while ( my $line = <$hg_in> ) {
	  if (my ($k,$v) = $line =~ m/^(\w+):\s+(.+)/) {
		$rv{$k} = $v;
	  }
	}
	$rv{'changeset'} =~ s/^\d+://;
  } else {
	$rv{error} = $!;
  }
  return %rv;
}



1;
