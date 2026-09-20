#!/bin/bash

SOCKET_PATH="/tmp/words_socket"

# Connect using netcat (socat is actually better for UNIX sockets, but netcat works in some implementations)
# If netcat does not support UNIX sockets, you can use socat instead:
# echo ">" | socat - UNIX-CONNECT:$SOCKET_PATH

# For systems with netcat-openbsd supporting -U:
#echo ">" | nc -U $SOCKET_PATH

# Send ">" and read one line
echo ">na" | socat - UNIX-CONNECT:$SOCKET_PATH | { IFS= read -r line; echo "$line"; }
