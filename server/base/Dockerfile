FROM matya/rudder-testsuite:base
MAINTAINER Janos Mattyasovszky <mail@matya.hu>

RUN \
	apt-get -y --no-install-recommends install \
		apache2 apache2-utils libapache2-mod-wsgi postgresql postgresql-client \
		ldap-utils rsyslog rsyslog-pgsql openjdk-7-jre-headless git-core libltdl7 dmidecode rsync uuid-runtime && \
	{ printf '[user]\nname = Root of the System\nemail = root@local.docker' > /root/.gitconfig; } && \
	cp /rudder/conf/vhost-relayize.conf /etc/apache2/sites-available/rudder-relayize.conf && \
	a2enmod cgid && \
	a2ensite rudder-relayize

ONBUILD ADD \
	. \
	/rudder/

ONBUILD RUN \
	sed "s|%VERSION|$(lsb_release -cs)|" /rudder/rudder.list > /etc/apt/sources.list.d/rudder.list && \
 	apt-get -y update && \
	apt-get -y --no-install-recommends install \
		rudder-inventory-ldap && \
	if [ -f /etc/default/rudder-slapd ]; then \
		sed -i 's/^RUDDER_CACHESIZE=.*/RUDDER_CACHESIZE="noauto"/g' /etc/default/rudder-slapd; \
	else \
		echo 'RUDDER_CACHESIZE="noauto"' > /etc/default/rudder-slapd; \
	fi && \
	/etc/init.d/rudder-slapd start && \
	/etc/init.d/postgresql start && \
	apt-get -y --no-install-recommends install \
		rudder-server-root && \
	SUBNET=$( ip ro sh dev eth0 | grep 'scope link' | cut -f1 -d' ' ) && \
	{ printf "${SUBNET}\nno\n\n" | /opt/rudder/bin/rudder-init; } && \
	/etc/init.d/rudder-slapd stop && \
	rm /var/rudder/ldap/backup/openldap-data-*.ldif && \
	/etc/init.d/postgresql stop && \
	chmod +x /etc/my_init.d/* /etc/service/*/run /rudder/bin/* && \
	touch /etc/rc2.d/S00rudder-slapd /etc/rc2.d/S00rudder-jetty

ONBUILD ENTRYPOINT [ "/sbin/my_init" ]
