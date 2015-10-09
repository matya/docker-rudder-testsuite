#!/bin/bash

exec 2>&1

UUID="$1"
echo "Promoting node to relay: $UUID"

echo "Forcing inventory processing:"
/var/rudder/cfengine-community/bin/cf-agent -KI -b sendInventoryToCmdb | awk -F '@#' '/root-distributePolicy/  {print $NF}'

echo "Accepting node:"
bash /rudder/bin/accept_pending.sh $UUID

echo "Promote to relay:"
/opt/rudder/bin/rudder-node-to-relay $UUID

echo "Regenerate promises:"
curl -s http://localhost:8080/rudder/api/deploy/reload; echo "";

echo "Exit"
exit 0
