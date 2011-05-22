.PHONY: FORCE
.SUFFIXES:
.DELETE_ON_ERROR:

SHELL:=/bin/bash

# sort locally to ensure locale consistency
e-nm.ls:
	mysql -BN -h localhost -u anonymous -D homo_sapiens_core_61_37f \
		-e "select distinct display_label from xref where display_label like 'NM\_0%'" \
	| sort >$@

%-ensembl.exhash: %.ls
	./ensembl-exon-hash <$@ >$@ >$@.log

%-ncbi.exhash: %.ls
	env - ./ncbi-exon-hash <$@ >$@ >$@.log

%.hashcmp: %-ensembl.exhash %-ncbi.exhash 
	join <(sort $(word 1,$^)) <(sort $(word 2,$^)) \
	| perl -ape 'print $$F[1]==$$F[2] ? "*" : " "' >$@

%-exondiff:
	diff <(./ensembl-tx-exons $*) <(env - ./ncbi-tx-exons $*)
