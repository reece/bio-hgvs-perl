#!/bin/bash
# run like this:
# ./t/hgvs-web-service.sh | diff t/hgvs-web-service.out -

port=${1:-7888}

ve  () { echo + "$@"     ; $@; }
ve2 () { echo + "$@" 1>&2; $@; }

ve curl -s "http://localhost:$port/chr-slice/chr=6&start=150000"
ve curl -s "http://localhost:$port/chr-slice/chr=6&start=150000"
ve curl -s "http://localhost:$port/hgvs/translate/NM_003227.3:c.2137G>A"
ve curl -s "http://localhost:$port/hgvs/translate/NC_000007.13:g.100224453T>G"
ve curl -s "http://localhost:$port/hgvs/translate/NM_003227.3:c.2069A>C"
ve curl -s "http://localhost:$port/hgvs/translate/NP_003218.2:p.Gln690Pro"
ve curl -s "http://localhost:$port/hgvs/translate/NC_000007.13:g.100225384delG"

#expect exceptions (as <error> tags in xml)
ve curl -s "http://localhost:$port/chr-slice/chr=bogus&start=150000"
ve curl -s 'http://localhost:$port/hgvs/translate/NM_000055.2:r.561_562A>G'
ve curl -s "http://localhost:$port/hgvs/translate/NM_003227.3:c.2137insAAA"
ve curl -s "http://localhost:$port/hgvs/translate/NM_003227.3:c.1665delC"
ve curl -s "http://localhost:$port/hgvs/translate/NP_003218.2:p.Pro555fx"
