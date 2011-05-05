=head1 NAME

  Bio::HGVS::HGVSVariantParser -- 

=head1 SYNOPSIS

  use Bio::HGVS::HGVSVariantParser;
  my $parser = Bio::HGVS::HGVSVariantParser->new();
  my $variant = $parser->parse('NM_0123.4:g.56A>T');

=head1 DESCRIPTION

Bio::HGVS::HGVSVariantParser is a parser for variations in the
syntax recommended by the Human Genome Variation Society.

=cut


package Bio::HGVS::Parser;

use strict;
use warnings;

use Carp::Assert;
use Parse::RecDescent;

use Bio::HGVS::Errors;
use Bio::HGVS::Variant;
use Bio::HGVS::Range;
use Bio::HGVS::Position;


$::RD_ERRORS = 1;
$::RD_HINT = 1;


=head1 METHODS

=cut

############################################################################

=head2 ->new()

creates a new parser. No arguments are expected.

=cut

# TODO: Implement class as a singleton

sub new {
  my ($class) = @_;
  my $self = bless({},$class);
  my $p = Parse::RecDescent->new( __hgvs_grammar() );
  (defined $p)
	or throw Bio::HGVS::Error("Couldn't compile HGVS parser grammar\n");
  $self->{_parser} = $p;
  return $self;
}


############################################################################

=head2 ->parse(I<hgvs_string>)

parses I<hgvs_string> into a Bio::HGVS::Variant.  See also
parse_hash.

=cut

sub parse {
  my ($self,$hgvs) = @_;
  my $h = $self->parse_hash($hgvs);
  assert( not (exists $h->{intron_offset} and exists $h->{end}),
		  "using intron_offest and end not currently supported");
  return Bio::HGVS::Variant->new(
	loc => Bio::HGVS::Range->easy_new( $h->{start}, $h->{intron_offset},
									   $h->{end}, undef ),
	( map { $_ => $h->{$_} } (qw(pre post type ref rpt_min rpt_max)) )
   );
}


############################################################################

=head2 ->parse_hash(I<hgvs_string>)

parses I<hgvs_string> into a hash.  This method is provided for cases
where a Bio::HGVS::Variant is not desired.

=cut

sub parse_hash {
  my ($self,$hgvs) = @_;
  my $r = $self->{_parser}->startrule($hgvs);
  if (not defined $r) {
	throw Bio::HGVS::SyntaxError("Couldn't parse HGVS string '$hgvs'");
  }
  return $r;
}



############################################################################
## INTERNAL FUNCTIONS
sub __hgvs_grammar {
  local $/ = undef;
  return <DATA>;
}


=head1 BUGS and CAVEATS

=head1 SEE ALSO

=head2 Bio::HGVS::

Bio::HGVS::Variant,  Bio::HGVS::VariantFormatter

=head2 Other modules

Ensembl::Variation

=head2 Links

=over

=item mutnomen

=back

=head1 AUTHOR and LICENSE

=cut

1;



############################################################################
## GRAMMAR
# See http://www.hgvs.org/mutnomen/
# HGVS is challenging to parse.  The following grammar will need to evolve
# as nuances and implications of the spec become better understood (by me,
# at least).

# TODO: extend for lists of variants on the same ref
# FIXME: accommodate all legit numbering, e.g. W+X_Y+Z (not accepted now)

__DATA__

startrule: hgvs_na | hgvs_aa

hgvs_na: ref ':' na_type '.' na_var
  { $return = { ref => $item{ref}, type => $item{na_type}, %{$item{na_var}} }; }
hgvs_aa: ref ':' aa_type '.' aa_var
  { $return = { ref => $item{ref}, type => $item{aa_type}, %{$item{aa_var}} }; }


na_type: m/[cgmr]/
na_var: na_subs | na_ins | na_del | na_dup | na_rpt
na_subs: na_loc na_pre '>' na_post
  { $return = { %{$item{na_loc}}, op => 'sub',
				pre => $item{na_pre}, post => $item{na_post} }; }
na_ins: na_loc 'ins' na_seq
  { $return = { %{$item{na_loc}}, op => $item{__STRING1__},
				pre => '', post => $item{na_seq} }; }
na_dup: na_loc 'dup' na_seq
  { $return = { %{$item{na_loc}}, op => $item{__STRING1__},
				pre => $item{na_seq}, post => '' }; }
na_del: na_loc 'del' na_seq 
  { $return = { %{$item{na_loc}}, op => $item{__STRING1__},
				pre => $item{na_seq}, post => '' }; }
na_rpt: na_loc na_seq '(' rpt_min '_' rpt_max ')'
  { $return = { %{$item{na_loc}},
				op => 'rpt',
				pre => $item{na_seq},
				post => '',
				rpt_min => $item{rpt_min},
				rpt_max => $item{rpt_max},
			   }; }
na_loc:
    start '_' end        { $return = { start => $item{start}, end => $item{end} } }
  | start intron_offset  { $return = { start => $item{start}, 
									   intron_offset => $item{intron_offset} } }
  | start                { $return = { start => $item{start}, end => $item{start} } }
na_pre: na_seq
na_post: na_seq


aa_type: m/[p]/
# TODO: Extend beyond XxxNYyy syntax to ins,del,delins,fs (at least)
aa_var: aa3_pre int aa3_post
  { $return = { op => 'sub', pre => $item{aa3_pre},
				post => $item{aa3_post}, start => $item{int} }; }
  | aa3_pre int 'X'
  { $return = { op => 'sub', pre => $item{aa3_pre},
				post => 'Ter', start => $item{int} }; }
aa3_pre: aa3_seq
aa3_post: aa3_seq


ref: m/[A-Z]\w+(?:.\d+)?/

start: m/-?/ int
  { $return = $item{__PATTERN1__} . $item{int}; }
end: int
  { $return = $item{int}; }
intron_offset: m/[-+]/ int
  { $return = $item{__PATTERN1__} . $item{int}; }
rpt_min: int
rpt_max: int
int: m/\d+/

na:     m/[ACGTU]/
na_seq: m/[ACGTU]*/

aa:     m/[ACDEFGHIKLMNPQRSTVWY]/
aa_seq: m/[ACDEFGHIKLMNPQRSTVWY]*/

aa3:	 m/(Ala|Cys|Asp|Glu|Phe|Gly|His|Ile|Lys|Leu|Met|Asn|Pro|Gln|Arg|Ser|Thr|Val|Trp|Tyr)/
aa3_seq: m/(Ala|Cys|Asp|Glu|Phe|Gly|His|Ile|Lys|Leu|Met|Asn|Pro|Gln|Arg|Ser|Thr|Val|Trp|Tyr)+/
