p=7888

root=$(dirname $(dirname "$0"))
cmd="$root/t/hgvs-web-service.sh"
echo "# $cmd"

ve  () { echo + "$@"     ; $@; }
ve2 () { echo + "$@" 1>&2; $@; }


trap cleanup EXIT
cleanup () {
	set -x
	[ -n $pid ] && kill $pid
	wait
}


$root/bin/hgvs-web-service --port $p &
pid=$!
echo "hgvs-web-service started; pid $pid" 1>&2


set -x

$cmd $port >/tmp/1 2>&1

sudo service mysql restart
sleep 5

$cmd $port >/tmp/2 2>&1

diff /tmp/1 /tmp/2
