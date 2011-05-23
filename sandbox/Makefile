.PHONY: FORCE
.SUFFIXES:
.DELETE_ON_ERROR:

SHELL:=/bin/bash
LANG:=C

# sort locally to ensure locale consistency
e-nm.ls:
	mysql -BN -h localhost -u anonymous -D homo_sapiens_core_61_37f \
		-e "select distinct display_label from xref where display_label like 'NM\_0%'" \
	| sort >$@

%-ensembl.exhash: %.ls
	(time -p ./ensembl-exon-hash <$< >$@) 2>$@.log

%-ncbi.exhash: %.ls
	(env - time -p ./ncbi-exon-hash <$< >$@) 2>$@.log

%.hashcmp: %-ensembl.exhash %-ncbi.exhash 
	wc -l $^
	join <(sort $(word 1,$^)) <(sort $(word 2,$^)) \
	| perl -ape 'print($$F[1] eq $$F[2] ? "*" : " ")' \
	| sort >$@

%-exondiff:
	diff <(./ensembl-tx-exons $*) <(env - ./ncbi-tx-exons $*)



.PHONY: clean cleaner cleanest
clean:
	/bin/rm -f *~
cleaner: clean
	/bin/rm -f *.bak
cleanest: cleaner
	/bin/rm -f *.log *.exhash *.ls *.hashcmp
