FROM matya/rudder-testsuite:base
MAINTAINER Janos Mattyasovszky <mail@matya.hu>

ONBUILD ADD \
	. \
	/rudder/

ONBUILD RUN \
        sed "s|%VERSION|$(lsb_release -cs)|" /rudder/rudder.list > /etc/apt/sources.list.d/rudder.list && \
        apt-get -y update && \
        apt-get -y --no-install-recommends install \
                rudder-agent && \
        { echo "unset" > /opt/rudder/etc/uuid.hive; }

ONBUILD ENTRYPOINT [ "/sbin/my_init" ]
