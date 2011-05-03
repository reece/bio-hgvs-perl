.SUFFIXES:
.PHONY: FORCE
.DELETE_ON_ERROR:

SHELL:=/bin/bash
export PATH=/usr/bin:/bin

export PERL5LIB=ext/lib/perl5
PERL_MODULES:=App::cpanminus Mojolicious MojoX::Renderer::TT


default:
	@echo ${PERL_MODULES_PMs}
	@echo "There ain't no stinkin' $@ rule, cowboy" 1>&2; exit 1


PERL_MODULES_PMs:=$(addprefix ${PERL5LIB}/,$(addsuffix .pm,$(subst ::,/,${PERL_MODULES})))
ext: ${PERL_MODULES_PMs}
${PERL5LIB}/%.pm: ${PERL5LIB}/App/cpanminus.pm
${PERL5LIB}/%.pm: FORCE
	@p="$*"; m=$${p//\//::}; \
	echo ===========================================================================; \
	echo === INSTALLING $$m; \
	echo ===========================================================================; \
	curl -Ls http://cpanmin.us | perl - --local-lib ext $$m


datetag:
	D=$$(/bin/date +r%Y%m%d); hg tag "$$D"; hg commit


.PHONY: clean cleaner cleanest
clean:
	find . \( -name '*~' -o -name '*.bak' -o -name '#*#' \) -print0 | xargs -0 rm -fv
cleaner: clean
	find . -name '*pyc' -o -name '*.orig' -print0 | xargs -0 rm -fv
cleanest: cleaner
	rm -fr ext
