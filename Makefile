.SUFFIXES:
.PHONY: FORCE
.DELETE_ON_ERROR:

export PATH=/usr/bin:/bin

default:
	@echo "There ain't no stinkin' $@ rule, cowboy" 1>&2; exit 1


#test: TBD


.PHONY: clean cleaner cleanest
clean:
	find . \( -name '*~' -o -name '*.bak' -o -name '#*#' \) -print0 | xargs -0 rm -fv
cleaner: clean
cleanest: cleaner
	find . -name '*pyc' -print0 | xargs -0 rm -fv
