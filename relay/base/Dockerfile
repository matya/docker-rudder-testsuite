FROM matya/rudder-testsuite:base
MAINTAINER Janos Mattyasovszky <mail@matya.hu>

ONBUILD ADD \
	. \
	/rudder/

RUN \
	apt-get -y --no-install-recommends install \
		apache2 apache2-utils rsyslog uuid-runtime dmidecode libltdl7 rsync && \
	a2enmod dav dav_fs && \
	a2dissite *efault && \
	/etc/init.d/apache2 stop && \
	mkdir -p /opt/rudder/etc /var/log/rudder/apache2 /var/rudder/share && \
	for i in /var/rudder/inventories/incoming /var/rudder/inventories/accepted-nodes-updates /var/rudder/oval/accepted-nodes-reports; do \
		mkdir -p ${i} && \
		chmod -R 1770 ${i} && \
		for group in apache www-data www; do \
			if getent group ${group} > /dev/null; then chown -R root:${group} ${i}; break; fi; \
		done; \
	done && \
	for i in /opt/rudder/etc/htpasswd-webdav-initial /opt/rudder/etc/htpasswd-webdav; do \
		/usr/bin/htpasswd -bc ${i} rudder rudder; \
	done && \
	touch /opt/rudder/etc/rudder-networks.conf && \
	cp /rudder/conf/vhost-rudder.conf /etc/apache2/sites-enabled/rudder-default 


ONBUILD RUN \
        sed "s|%VERSION|$(lsb_release -cs)|" /rudder/rudder.list > /etc/apt/sources.list.d/rudder.list && \
        apt-get -y update && \
        apt-get -y --no-install-recommends install \
		rudder-agent && \
	{ echo "unset" > /opt/rudder/etc/uuid.hive; }


