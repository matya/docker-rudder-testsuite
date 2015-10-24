#!/bin/bash

: ${IMAGEBASE:=matya/rudder-testsuite}
: ${VERSION:=latest}

set -e

echo "[[[[[ Build ]]]]]"
for T in \
    dns \
    base \
    client.base relay.base server.base \
    client.${VERSION} relay.${VERSION} server.${VERSION}; do
        if grep -F -q '.' <<<"$T"; then
            DIR="${T%%.*}/${T#*.}"
        else
            DIR="$T"
        fi
        [[ -e ${DIR}/Dockerfile.internal ]] && DF="Dockerfile.internal" || DF="Dockerfile"
        ( set -o pipefail; cd ${DIR}; docker build -t ${IMAGEBASE}:${T} -f $DF .  | strings | sed "s|^|$T>> |g" );
        echo "=================================================================";
done
echo ""
