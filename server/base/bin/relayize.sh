#!/bin/bash

UUID="$1"
echo "[relayize:$$]** Promoting node to relay: $UUID"

echo "[relayize:$$] - Forcing inventory processing:"
/var/rudder/cfengine-community/bin/cf-agent -KI -b sendInventoryToCmdb | awk -F '@#' '/root-distributePolicy/  {print $NF}'

echo "[relayize:$$] - Accepting node:"
bash /rudder/bin/accept_pending.sh $UUID || { echo "Failed to accept node!"; exit 1; }

echo "[relayize:$$] - Promote to relay:"
/opt/rudder/bin/rudder-node-to-relay $UUID || { echo "Failed to promote!"; exit 1; }

echo "[relayize:$$] - Regenerate promises:"
curl -s http://localhost:8080/rudder/api/deploy/reload; echo "";
sleep 2

while : ; do
    [[ -f /var/rudder/share/$UUID/rules/cfengine-community/rudder_promises_generated ]] && break
    echo "[relayize:$$] - Waiting for promises being generated..."
    sleep 15
done
grep -q "^$UUID" /var/relayize/relays.txt || { echo "$UUID" >> /var/relayize/relays.txt; }

echo "[relayize:$$]** Exit"
exit 0
