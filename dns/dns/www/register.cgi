#!/bin/sh
echo -e "Content-type: text/plain\r\n";

HOST="$QUERY_STRING"
IP="$REMOTE_ADDR"

touch /var/run/hosts.lock
if ! exec 200</var/run/hosts.lock; then
  echo "Could not flock" >&2
  exit 1
fi

flock 200
if grep -q "^$IP\s" /etc/hosts; then
    sed "s/^$IP\s.*/$IP $HOST $HOST/g" /etc/hosts > /var/tmp/hosts.new
    cat /var/tmp/hosts.new > /etc/hosts
    rm /var/tmp/hosts.new
else
    echo "$IP $HOST $HOST" >> /etc/hosts
fi
flock -u 200

pkill -HUP dnsmasq
echo "Registered '$IP' as '$HOST'." | tee /dev/stderr
exit 0

