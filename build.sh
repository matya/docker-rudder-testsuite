#!/bin/bash

: ${RTS_IMAGE:=matya/rudder-testsuite}
: ${RTS_RELEASE:=latest}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --release|-R)
            grep -q '^-' <<<"$2" && { echo "$1 requires an argument"; exit 1; }
            RTS_RELEASE="$2";
            shift;
            ;;
        --image|-I)
            grep -q '^-' <<<"$2" && { echo "$1 requires an argument"; exit 1; }
            RTS_IMAGE="$2";
            shift;
            ;;
        --help|-h)
            echo "
Usage: $0 
    [--image|-I]   <image>      Docker image name, default: ${RTS_IMAGE}
    [--release|-R] <release>    Rudder release to build as tag of <image>, default: ${RTS_RELEASE}.
"
            exit 0
            ;;
        *)
            echo "-> Unknown parameter: $1. See $0 --help for usage"
            exit 1
            ;;
    esac
    shift
done   

set -e

echo "[[[[[ Build ]]]]]"
for T in \
    dns \
    base \
    client.base relay.base server.base \
    client.${RTS_RELEASE} relay.${RTS_RELEASE} server.${RTS_RELEASE}; do
        if grep -F -q '.' <<<"$T"; then
            DIR="${T%%.*}/${T#*.}"
        else
            DIR="$T"
        fi
        [[ -e ${DIR}/Dockerfile.internal ]] && DF="Dockerfile.internal" || DF="Dockerfile"
        ( set -o pipefail; cd ${DIR}; docker build -t ${RTS_IMAGE}:${T} -f $DF .  | awk '{ print "'$T'>> " $0; fflush(); }'; )
        echo "=================================================================";
done
echo ""
