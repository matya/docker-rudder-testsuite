#!/bin/bash

## Author: Janos Mattyasovszky, 2015,
## See https://hub.docker.com/r/matya/rudder-testsuite/ for details.

####
## This script currently serves as a pretty primitive way for Orchestration
## The main actions is does:
##  - start a Rudder Server, wait until it's started
##    - start the Relays in a loop, link with the Server
##      - after a Relay has started, start all it's nodes, link with it's Relay
##
## Currently only one Server and the same local docker server are supported
## Todo: Look for a real orchestration method / framework
####

### Settings some defaults if not already provided by environment
### can be overwritten later by CLI tools.

: Setting ${RTS_IMAGE:=matya/rudder-testsuite}
: Setting ${RTS_COLOR:=1}
: Settnig ${RTS_SSL_PORT_1:=443}
: Setting ${RTS_PREFIX:=rts}
: Setting ${RTS_RELEASE:=latest}

### Parse CLI variables
R=1
RELAYS=()
while [[ $# -gt 0 ]]; do 
    case "$1" in
        --relay|-r)
            if grep -q '^-' <<<"$2"; then
                C=0
            else
                C=$(( $2 + 0 )) || { echo "-r requires an integer number as argument"; exit 1; }
                shift;
            fi
            RELAYS+=( [$((R++))]=$C )
            ;;
        --color|-c)
            RTS_COLOR=1 
            ;;
        --no-color|-C)
            RTS_COLOR=0
            ;;
        --release|-R)
            grep -q '^-' <<<"$2" && { echo "--release requires an argument"; exit 1; }
            RTS_RELEASE="$2";
            shift;
            ;;
        --cleanup)
            echo "The following containers are going to be deleted:"
            echo "";
            IDS=$( 
                docker ps -a | awk -v "P=^${RTS_PREFIX}" -v "I=^${RTS_IMAGE}:" '
                    # Header
                    NR==1             { print > "/dev/stderr"; } 
                    # Show full line as info on stderr for the human eye and the ID on stdout for variable IDS
                    $2 ~ I && $NF ~ P { print > "/dev/stderr"; print $1; }
                ' );
            echo "";
            [[ -z "$IDS" ]] && { 
                echo "No containers found matching the current Image '${RTS_IMAGE}' and Name-Prefix '${RTS_PREFIX}'"; 
                echo "";
                exit 0;
            }
            read -p 'Are you sure? [yes/N] ' ANSWER;
            [[ x"$ANSWER" = x"yes" ]] || { 
                echo "Aborted"; 
                echo "";
                exit 0; 
            }
            docker rm -f $IDS > /dev/null;
            exit $?;
            ;;
    esac
    shift;
done


if [[ -z "$RTS_RELEASE" ]]; then
    echo "Error: need option --release <rel>, where <rel> can be:"
    echo "  2.11.latest"
    echo "  3.0.latest"
    echo "  3.1.latest"
    exit 0
fi

if ((RTS_COLOR)); then
    declare -rx BOLD="$(tput bold)"
    declare -rx RED="$(tput bold; tput setaf 1)"
    declare -rx GREEN="$(tput bold; tput setaf 2)"
    declare -rx YELLOW="$(tput bold; tput setaf 3)"
    declare -rx RESET="$(tput sgr0 )"
    declare -rx UL="$( tput smul )"
else
    declare -rx BOLD="" RED="" GREEN="" YELLOW="" RESET="" UL=""
fi

format="%s%-6s%s %s\n"; nl="$(printf "\n")"
function p()  { printf "%s %-45s " "->" "$@"; }
function e()  { printf "%s%-6s%s\n %s\n" "$RED" "[ERROR]" "$RESET" " ${BOLD} *** $1 ${RESET}"; [[ -n "$2" ]] && echo -e "$2"; exit 1; }
function w()  { printf "$format" "$YELLOW" "[WARN]" "$RESET" "${@:+ $@}"; }
function ok() { printf "$format" "$GREEN"  "[OK]"   "$RESET" "${@:+ $@}"; }


## main.cf :)

function waitfor() {
    local ID="$1"
    local SLEEP="${2:-5}"
    local MAXWAIT="${3:-600}"
    local CURRWAIT=0
    while : ; do
        (( CURRWAIT > MAXWAIT )) && return 1
        docker exec "$ID" test -f /rudder/system-started 2> /dev/null && return 0
        sleep $SLEEP
        (( CURRWAIT += SLEEP ))
    done
}

if [[ $(docker images 2>&1 | awk -v "REPO=${RTS_IMAGE}" '$1 == REPO { print $2 }' | grep -c -E "^(server|relay|client).${RTS_RELEASE}$") -ne 3 ]]; then
    echo "Error: Need the following images available on the local system to start:"
    echo ""
    echo "  ${RTS_IMAGE}:"
    echo "         server.${RTS_RELEASE}"
    echo "         relay.${RTS_RELEASE}"
    echo "         client.${RTS_RELEASE}"
    echo ""
    exit 1
fi    

p "Checking for running instances"
RUNNING=$( docker ps -q --filter "name=${RTS_PREFIX}_*" 2>&1 ) || e "Failed command to query instances: $RUNNING"
if ! [[ -z "$RUNNING" ]]; then
    e "We already have containers running with name '${RTS_PREFIX}_*'. Use --cleanup to kill the"
else
    ok "Nothing running"
fi
# We need some cap's because of start-stop-daemon
## see @ https://github.com/docker/docker/issues/6800

# Currently we only support a tree of one Root Server, but I'll keep the loop for the future

p "Starting DNS Server"
E=$(
    docker run -d \
        --name "${RTS_PREFIX}_dns" --hostname "${RTS_PREFIX}_dns" \
            ${RTS_IMAGE}:dns
    2>&1 ) || e "Failed" "$E"            
ok "system started"
sleep 2

for MASTERNUMBER in 1; do
    MASTERNAME=$( printf "%s_m%02i" "${RTS_PREFIX}" "$MASTERNUMBER" )
    SSLPORT="$( tmp="RTS_SSL_PORT_${MASTERNUMBER}"; echo ${!tmp}; )"

    p "Starting Master Server #${MASTERNUMBER}"
    E=$( 
        docker run -d \
            --name "$MASTERNAME" --hostname="$MASTERNAME" \
            --cap-add=SYS_PTRACE \
            --link "${RTS_PREFIX}_dns:dns" \
            -p ${SSLPORT}:443 \
                ${RTS_IMAGE}:server.${RTS_RELEASE}  
        2>&1 ) || e "Failed" "$E"
    ok "'$MASTERNAME' started with ${E:0:12} on port ${SSLPORT}"

    p "Waiting for services to start..."
    waitfor "$E" || e "Wait timeout breached"
    ok "system up as root"

    for RELAYNUMBER in ${!RELAYS[*]}; do
        RELAYNAME=$( printf "%s_r%02i" "$MASTERNAME" "$RELAYNUMBER" )

        p "Starting Relay #${RELAYNUMBER}..."
        E=$( 
            docker run -d \
                --name "$RELAYNAME" --hostname="$RELAYNAME" \
                --cap-add=SYS_PTRACE \
                --env "POLICY_SERVER=$MASTERNAME" \
                --link "${RTS_PREFIX}_dns:dns" \
                --link "$MASTERNAME:$MASTERNAME" \
                    ${RTS_IMAGE}:relay.${RTS_RELEASE} 
            2>&1 ) || e "Failed" "$E"
        ok "'$RELAYNAME' started with ${E:0:12}"

        p "Waiting for services to start..."
        waitfor "$E" || e "Wait timeout breached"
        UUID=$( docker exec "$E" cat /opt/rudder/etc/uuid.hive )
        ok "system up with UUID $UUID"

        if [[ ${RELAYS[$RELAYNUMBER]} -gt 0 ]]; then
            for CLIENTNUMBER in $( seq 1 ${RELAYS[$RELAYNUMBER]} ); do
                CLIENTNAME=$( printf "%s_c%04i" "$RELAYNAME" "$CLIENTNUMBER" )
                p "Starting Node #${CLIENTNUMBER}"
                E=$( 
                    docker run -d \
                        --name "$CLIENTNAME" --hostname="$CLIENTNAME" \
                        --cap-add=SYS_PTRACE \
                        --env "POLICY_SERVER=$RELAYNAME" \
                        --link "${RTS_PREFIX}_dns:dns" \
                        --link "$RELAYNAME:$RELAYNAME" \
                            ${RTS_IMAGE}:client.${RTS_RELEASE} 
                    2>&1 ) || e "Failed" "$E"
                ok "'$CLIENTNAME' started with ${E:0:12}"
            done
        fi
    done
done

echo ""
docker ps | grep " ${RTS_PREFIX}_"

exit 0
