package Bio::HGVS::utils;

use base 'Exporter';
our @EXPORT_OK = qw(aa3 aa3_re);


my @aa3 = qw(Ala Arg Asn Asp Cys Gln Glu Gly His Ile Leu
			  Lys Met Phe Pro Ser Thr Trp Tyr Val);

my $aa3_re = join('|',@aa3);
$aa3_re = qr/$aa3_re/;


1;

