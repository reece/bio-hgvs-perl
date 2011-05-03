.SUFFIXES:
.PHONY: FORCE
.DELETE_ON_ERROR:

export PATH=/usr/bin:/bin

default:
	@echo "There ain't no stinkin' $@ rule, cowboy" 1>&2; exit 1

ext: FORCE
	sh -c 'curl -L http://cpanmin.us | perl - --local-lib libx Mojolicious'

datetag:
	D=$$(/bin/date +r%Y%m%d); hg tag "$$D"; hg commit

.PHONY: clean cleaner cleanest
clean:
	find . \( -name '*~' -o -name '*.bak' -o -name '#*#' \) -print0 | xargs -0 rm -fv
cleaner: clean
cleanest: cleaner
	find . -name '*pyc' -o -name '*.orig' -print0 | xargs -0 rm -fv
