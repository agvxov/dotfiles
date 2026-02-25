#!/bin/bash
function personal_watch(){
	declare -a CMD

    export SPECIAL_DATES=$(cat ${HOME}/stow/.data/dates.cfg | tr -d '\n')

	FORMATED_DATE="date '+%H : %M : %S' | figlet -w ${COLUMNS} -f Small"
    TO_YELLOW="sed 's/^/\o033[1;33m/;s/$/\o033[0m/'"
    CAL="calmark.pl"
	CMD+=("paste <($CAL) <(${FORMATED_DATE} | ${TO_YELLOW}; day.pl);")

	CMD+=("echo -e '\033[0m';")

	CMD+=("trade.pl ;")

	CMD+=("echo '';")

	CMD+=("life.pl;")

	CMD+=("echo '';")

	CMD+=("alias_of_the_day.sh;")

	#CMD+=("nevnapok.sh;")

	echo ${CMD[@]}
	watch --no-title --color --precise -n 1 "${CMD[@]}"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    COLUMNS=$(tput cols 2>/dev/null)
    personal_watch
else
    alias w="personal_watch"
fi
