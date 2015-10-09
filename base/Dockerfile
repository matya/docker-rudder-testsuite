FROM phusion/baseimage:latest
MAINTAINER Janos Mattyasovszky <mail@matya.hu>

ENV \
	DEBIAN_FRONTEND=noninteractive 

RUN \
	apt-get update && \
	apt-get -y --no-install-recommends install \
		rsyslog dmidecode uuid-runtime htop && \
	apt-get -y autoremove

RUN \
	curl -s "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x474A19E8" | apt-key add - && \
	apt-get update

ONBUILD ADD \
	. \
	/rudder/

ONBUILD RUN \
	rm -rf /etc/service/* /etc/my_init.d/00_regen_ssh_host_keys.sh && \
	if test -d /rudder/init.d/; then \
		ls -1 /rudder/init.d/* 2> /dev/null | xargs --no-run-if-empty cp -vt /etc/my_init.d/; \
	fi && \
	if test -d /rudder/service; then \
		for srvfile in /rudder/service/*; do \
			srvname=$( basename $srvfile ) && \
			mkdir -p /etc/service/$srvname && \
			cp -v $srvfile /etc/service/$srvname/run; \
		done; \
	fi 

ENTRYPOINT echo "This image is not intended to be run directly, it only serves as a base for versioned instances"; exit 1;
