#!/bin/bash

echo -e "Content-type: text/plain\r\n";

UUID="$QUERY_STRING"
PIPE=/var/run/relayize.socket

[[ -p $PIPE && -w $PIPE ]] || { echo "Error: Pipe not writable"; exit 1; }

echo "$UUID" > $PIPE

echo "Saved for processing"
exit 0

