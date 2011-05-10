#!/bin/bash

# run like this:
# ./t/hgvs-web-service.sh | diff t/hgvs-web-service.out -

p=7878
hwslog=/tmp/t-hgvs-web-service.log

root=$(dirname $(dirname "$0"))

ve  () { echo + "$@"     ; $@; }
ve2 () { echo + "$@" 1>&2; $@; }


trap cleanup EXIT
cleanup () {
	if [ -n "$pid" -a -d /proc/$pid ]; then 
		ve2 kill "$pid"
		sleep 1
		if [ -e /proc/$pid ]; then
			ve2 kill -9 "$pid"
		fi
		wait
	fi
}


$root/bin/hgvs-web-service --port $p >"$hwslog" 2>&1 &
pid=$!
echo "hgvs-web-service started; pid $pid" 1>&2
echo "log in $hwslog" 1>&2
sleep 3

ve curl -s "http://localhost:$p/chr-slice/chr=6&start=150000"
ve curl -s "http://localhost:$p/chr-slice/chr=d6&start=150000"
ve curl -s "http://localhost:$p/chr-slice/chr=6&start=150000"

ve curl -s "http://localhost:$p/hgvs/translate/NM_003227.3:c.2137G>A"
ve curl -s "http://localhost:$p/hgvs/translate/NM_003227.3:c.2137insAAA"
ve curl -s "http://localhost:$p/hgvs/translate/NC_000007.13:g.100224453T>G"
ve curl -s "http://localhost:$p/hgvs/translate/NM_003227.3:c.2069A>C"
ve curl -s "http://localhost:$p/hgvs/translate/NP_003218.2:p.Gln690Pro"
ve curl -s "http://localhost:$p/hgvs/translate/NC_000007.13:g.100225384delG"
ve curl -s "http://localhost:$p/hgvs/translate/NM_003227.3:c.1665delC"
ve curl -s "http://localhost:$p/hgvs/translate/NP_003218.2:p.Pro555fx"

