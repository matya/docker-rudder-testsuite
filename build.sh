#!/bin/bash

: ${IMAGEBASE:=test}
: ${VERSION:=latest}

set -e

echo "[[[[[ Build ]]]]]"
for T in \
    base \
    client.base relay.base server.base \
    client.${VERSION} relay.${VERSION} server.${VERSION}; do
        docker build -q -t ${IMAGEBASE}:${T}     ${T%%.*}/${T#*.} | sed "s|^|$T>> |g";
        echo "=================================================================";
done
echo ""
