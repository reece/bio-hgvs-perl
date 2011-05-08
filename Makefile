.SUFFIXES:
.PHONY: FORCE
.DELETE_ON_ERROR:

SHELL:=/bin/bash
export PATH=/usr/bin:/bin

EXT_ROOT:=ext
export PERL5LIB=${EXT_ROOT}/lib/perl5
PERL_MODULES:=App::cpanminus TryCatch MojoX::Renderer::TT Mojolicious


default:
	@echo ${PERL_MODULES_PMs}
	@echo "There ain't no stinkin' $@ rule, cowboy" 1>&2; exit 1


PERL_MODULES_PMs:=$(addprefix ${PERL5LIB}/,$(addsuffix .pm,$(subst ::,/,${PERL_MODULES})))
${EXT_ROOT}: ${PERL_MODULES_PMs}

# installing cpanminus didn't work until I did:
# (Ubuntu 10.10)
get-dist-modules:
	sudo apt-get install libextutils-depends-perl libmodule-build-perl libversion-perl	\
		libcpan-meta-perl libparse-cpan-meta-perl libversion-requirements-perl			\
		libparse-method-signatures-perl libscope-upper-perl								\
		libextutils-depends-perl libb-hooks-endofscope-perl								\
		libb-hooks-op-check-perl libmoosex-types-perl libb-hooks-op-ppaddr-perl			\
		libdevel-declare-perl libvariable-magic-perl
${PERL5LIB}/App/cpanminus.pm: get-dist-modules
	curl -Ls http://cpanmin.us | perl - --local-lib ${EXT_ROOT} --self-upgrade
${PERL5LIB}/%.pm: ${PERL5LIB}/App/cpanminus.pm
${PERL5LIB}/%.pm: FORCE
	@p="$*"; m=$${p//\//::}; \
	echo ===========================================================================; \
	echo === INSTALLING $$m; \
	echo ===========================================================================; \
	curl -Ls http://cpanmin.us | perl - --local-lib ${EXT_ROOT} $$m


datetag:
	D=$$(/bin/date +r%Y%m%d); hg tag "$$D"; hg commit


.PHONY: clean cleaner cleanest
clean:
	find . \( -name '*~' -o -name '*.bak' -o -name '#*#' -o -name '#_*' \) -print0 | xargs -0 rm -fv
cleaner: clean
	rm -fr bin/tmp
	find . -name '*pyc' -o -name '*.orig' -print0 | xargs -0 rm -fv
cleanest: cleaner
	rm -fr ${EXT_ROOT}
