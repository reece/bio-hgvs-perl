.PHONY: FORCE
.SUFFIXES:
.DELETE_ON_ERROR:

SHELL:=/bin/bash
LANG:=C

# sort locally to ensure locale consistency
e62nm.ls:
	mysql -BN -h localhost -u anonymous -D homo_sapiens_core_62_37g \
		-e "select distinct display_label from xref where display_label like 'NM\_%'" \
	| sort >$@

%-ensembl.exhash: %.ls
	(time -p ./ensembl-exon-hash <$< >$@) 2>$@.log

%-ncbi.exhash: %.ls
	(env - time -p ./ncbi-exon-hash <$< >$@) 2>$@.log

%.hashcmp: %-ensembl.exhash %-ncbi.exhash 
	wc -l $^
	join <(sort $(word 1,$^)) <(sort $(word 2,$^)) \
	| perl -ap \
		-e 'print ($$F[1] eq $$F[2] ? "==" : ($$F[1] =~ m/:\d+$$/ and $$F[2] =~ m/:\d+$$/) ? "!=" : "  " )' \
	| sort >$@

%-exondiff:
	diff -C30 <(./ensembl-tx-exons $*) <(env - ./ncbi-tx-exons $*)



.PHONY: clean cleaner cleanest
clean:
	/bin/rm -f *~
cleaner: clean
	/bin/rm -f *.bak
cleanest: cleaner
	/bin/rm -f *.log *.exhash *.ls *.hashcmp
