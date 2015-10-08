#!/bin/bash

: ${IMAGEBASE:=test}
: ${VERSION:=2.11}

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

echo "[[[[[ Start ]]]]]"

: TODO: Start N relays, with M agents each
