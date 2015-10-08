#!/bin/bash

NODEID="$1"
exec 2>&1

[[ -s /rudder/api-token ]] || { echo "*** No API Token found at /rudder/api-token!"; exit 1; }
API_KEY="$(</rudder/api-token)"

[[ -x /usr/bin/curl ]] || { echo "No curl binary found"; exit 1; }

if  /usr/bin/curl --silent -L -H "X-API-Token: $API_KEY"           "http://localhost:8080/rudder/api/latest/nodes/$NODEID?prettify=true" | grep -q '"status": "pending"'; then
    echo -n "** Accepting pending node $NODEID: "
    /usr/bin/curl --silent -L -H "X-API-Token: $API_KEY" -X 'POST' "http://localhost:8080/rudder/api/latest/nodes/pending/$NODEID?prettify=true" -d "status=accepted" | \
        grep -e '"result"'
    exit $?
else
    echo "Node not found or not pending: $NODEID"
    exit 1
fi

