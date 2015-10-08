#!/bin/bash

set -e
exec 2>&1

UUID="$1"
echo "Promoting node to relay: $UUID"

echo "Forcing inventory processing:"
/var/rudder/cfengine-community/bin/cf-agent -KI -b sendInventoryToCmdb | awk -F '@#' '/root-distributePolicy/  {print $NF}'
sleep 1

echo "Accepting node:"
bash /rudder/bin/accept_pending.sh $UUID
sleep 1

echo "Promote to relay:"
/opt/rudder/bin/rudder-node-to-relay $UUID

echo "Regenerate promises:"
curl -s http://localhost:8080/rudder/api/deploy/reload; echo "";

echo "Exit"
exit 0
