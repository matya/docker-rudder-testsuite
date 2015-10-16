#!/bin/bash

BASEURL="http://localhost:8080/rudder/api/latest"
SLAPD_CONFIG=/opt/rudder/etc/openldap/slapd.conf
NODEID="$1"
exec 2>&1

[[ -s /rudder/api-token ]] || { echo "*** No API Token found at /rudder/api-token!"; exit 1; }
API_KEY="$(</rudder/api-token)"

[[ -x /usr/bin/curl ]] || { echo "No curl binary found"; exit 1; }
api() {
    local p="$1"; shift;
    /usr/bin/curl --silent -L -H "X-API-Token: $API_KEY" "${BASEURL}/$p" $@
}

C=0
while :; do
    STATUS=$( api "nodes/$NODEID?prettify=true" | awk -F'"' '/"status":/ { print $(NF-1); exit; }' )
    if [[ x"$STATUS" = x"pending" ]]; then
        echo -n "- Accepting pending node $NODEID: "
        api "nodes/pending/$NODEID?prettify=true" -X 'POST' -d "status=accepted" | \
            grep -e '"result"'
        while :; do
            ROOT_DN=$( awk -F'"' '/^rootdn/ {print $2; exit;}' $SLAPD_CONFIG )
            ROOT_PW=$( awk       '/^rootpw/ {print $2; exit;}' $SLAPD_CONFIG )
            NODE_HOSTNAME=$(
                /usr/bin/ldapsearch -D "$ROOT_DN" -w "$ROOT_PW" -H 'ldap://127.0.0.1:389' \
                    -s base -b "nodeId=${NODEID},ou=Nodes,ou=Accepted Inventories,ou=Inventories,cn=rudder-configuration" \
                        nodeHostname 2>/dev/null | grep "^nodeHostname:" | sed 's%nodeHostname: %%'
                    )
            [[ -n "$NODE_HOSTNAME" ]] && break
            sleep 1
        done
        echo "- Node '$NODE_HOSTNAME' with UUID '$NODEID' is now accepted"
        exit 0
    elif [[ x"$STATUS" = x"accepted" ]]; then
        echo "- Node $NODEID already accepted"
        exit 0
    fi
    if (( C++ > 180 )); then
        echo "- Timeout of 15 minutes reached!"
        exit 1
    fi
    echo "- Waiting for node $NODEID to appear..."
    sleep 5
done

