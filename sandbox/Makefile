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



DBSNP_XML_DIR:=/srv/mirrors/ftp.ncbi.nih.gov/snp/organisms/human_9606/XML
DBSNP_XML_FILES:=$(subst ${DBSNP_XML_DIR}/,,$(wildcard ${DBSNP_XML_DIR}/ds_ch[XY0-9]*.xml.gz))
DBSNP_RSSUM_FILES:=$(DBSNP_XML_FILES:.xml.gz=.tsv.gz)
DBSNP_RSSUM_DIR:=dbsnp-rssum
.PHONY: ${DBSNP_RSSUM_DIR}
${DBSNP_RSSUM_DIR}: $(addprefix ${DBSNP_RSSUM_DIR}/,${DBSNP_RSSUM_FILES})
.PRECIOUS: ${DBSNP_RSSUM_DIR}/%.tsv.gz
${DBSNP_RSSUM_DIR}/%.tsv.gz: ${DBSNP_XML_DIR}/%.xml.gz
	@mkdir -p "${@D}"
	gzip -cdq <$< | ./dbsnp-rs-summary | gzip -cq >$@.tmp
	@mv -v $@.tmp $@

.PHONY: rs-%
rs: rs-0.001
rs-%: $(addprefix ${DBSNP_RSSUM_DIR}/,${DBSNP_RSSUM_FILES})
	@echo "# Building random sample at rate $*..."; \
	F=$$(mktemp --tmpdir="."); \
	gzip -cdq $^ | perl -ne 'print if rand()<$*' | gzip -cq >$$F; \
	read -n4 md5 fn < <(md5sum "$$F"); \
	mv -v "$$F" "$@-$$md5.tsv.gz"


.PHONY: clean cleaner cleanest
clean:
	/bin/rm -f *~
cleaner: clean
	/bin/rm -f *.bak
cleanest: cleaner
	/bin/rm -f *.log *.exhash *.ls *.hashcmp
