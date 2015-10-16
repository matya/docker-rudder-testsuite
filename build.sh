#!/bin/bash

: ${IMAGEBASE:=matya/rudder-testsuite}
: ${VERSION:=latest}

set -e

echo "[[[[[ Build ]]]]]"
for T in \
    base \
    client.base relay.base server.base \
    client.${VERSION} relay.${VERSION} server.${VERSION}; do
        [[ -e ${T%%.*}/${T#*.}/Dockerfile.internal ]] && DF="Dockerfile.internal" || DF="Dockerfile"
        ( cd ${T%%.*}/${T#*.}/; docker build -t ${IMAGEBASE}:${T} -f $DF .  | sed "s|^|$T>> |g" );
        echo "=================================================================";
done
echo ""
