.PHONY: FORCE
.SUFFIXES:
.DELETE_ON_ERROR:

PATH:=../bin:/usr/bin:/bin

default: test-web-service


test-web-service:
	( \
	set -x; \
	hgvs-web-service --port 7888 & pid=$$!; sleep 5; \
	./hgvs-web-service.sh 7888 >/tmp/1;     \
	./hgvs-web-service.sh 7888 >/tmp/2;     \
	diff /tmp/[12];                         \
	kill $$pid; wait                        \
	)


#    sudo service mysql restart; sleep 2;        \
