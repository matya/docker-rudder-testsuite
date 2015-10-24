FROM alpine:3.2
MAINTAINER Janos Mattyasovszky <mail@matya.hu>

ADD dns/ /dns/

RUN apk --allow-untrusted -U add dnsmasq /dns/apk/*.apk

EXPOSE 53/udp 15001
ENTRYPOINT [ "/dns/entry.sh" ]
