#!/bin/bash

BASEURL="http://localhost:8080/rudder/api/latest"
NODEID="$1"
exec 2>&1

[[ -s /rudder/api-token ]] || { echo "*** No API Token found at /rudder/api-token!"; exit 1; }
API_KEY="$(</rudder/api-token)"

[[ -x /usr/bin/curl ]] || { echo "No curl binary found"; exit 1; }
CURL="/usr/bin/curl --silent -L -H 'X-API-Token: $API_KEY'"
api() {
    local p="$1"; shift;
    $CURL "${BASEURL}/$p" $@
}

C=0
while :; do
    STATUS=$( api "nodes/$NODEID?prettify=true" | awk -F'"' '/"status":/ { print $(NF-1); exit; }' )
    if [[ x"$STATUS" = x"pending" ]]; then
        echo -n "- Accepting pending node $NODEID: "
        api "nodes/pending/$NODEID?prettify=true" -X 'POST' -d "status=accepted" | \
            grep -e '"result"'
        exit 0
    elif [[ x"$STATUS" = x"accepted" ]]; then
        echo "- Node already accepted"
        exit 0
    fi
    if (( C++ > 180 )); then
        echo "- Timeout of 15 minutes reached!"
        exit 1
    fi
    echo "- Waiting for node $NODEID to appear..."
    sleep 5
done

