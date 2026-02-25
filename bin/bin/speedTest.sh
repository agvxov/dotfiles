#!/bin/bash

# Ping latency test

enable -n echo

readonly NORMAL="\33[0m"
readonly BOLD="\33[1m"
readonly YELLOW="\33[33m"

DOMAIN="$(cat "$(dirname "$(realpath $0)")/../.data/speedTest_domain.var")"
PING=$(ping -c 10 ${DOMAIN})
DELAYS=($(echo "${PING}" | grep "bytes from" | cut -d "=" -f 4 | cut -d " " -f 1))

if [ -n $DELAYS ]; then
	H="0"
	for i in ${DELAYS[*]}; do
		H=$(bc < <(echo "$H + $i"))
	done

	H=$(bc < <(echo "$H / ${#DELAYS[*]}"))
else
	H="None"
fi

echo -e "${YELLOW}Suffered$(echo "$PING" | grep "packet loss" | cut -d "," -f 3).$NORMAL"
echo -e "${YELLOW}Your ping is: ${BOLD}${H}${NORMAL}"
