#!/bin/bash

exec 2>&1

UUID="$1"
echo "Promoting node to relay: $UUID"

echo "Forcing inventory processing:"
/var/rudder/cfengine-community/bin/cf-agent -KI -b sendInventoryToCmdb | awk -F '@#' '/root-distributePolicy/  {print $NF}'

echo "Accepting node:"
bash /rudder/bin/accept_pending.sh $UUID || { echo "Failed to accept node!"; exit 1; }

echo "Promote to relay:"
/opt/rudder/bin/rudder-node-to-relay $UUID || { echo "Failed to promote!"; exit 1; }
grep -q "^$UUID" /var/relayize/relays.txt || { echo "$UUID" >> /var/relayize/relays.txt; }

echo "Regenerate promises:"
curl -s http://localhost:8080/rudder/api/deploy/reload; echo "";

echo "Exit"
exit 0
