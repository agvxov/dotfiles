#!/bin/bash

enable -n echo
GREEN='\033[92m'
RED='\033[31m'
BOLD='\033[1m'
NORMAL='\033[0m'

function usage() {
	echo -e "${BOLD}TypeDirSort.sh [options]${NORMAL}"
	echo -e "	-h        : print this help message"
	echo -e "	-i [path] : specifies input directory; '.' by default"
	echo -e "	-o [path] : specifies output directory; '.' by default"
	echo -e "	-r        : recursive"
	echo -e "	-m        : move; do not copy"
	echo -e "	-d        : destructive; delete emptied out subdirectories; must be used with -m and -r"
}

RECURSIVE=""
OPERATION="cp"
DESTRUCTIVE=""
IDIR="."
ODIR="."

while getopts "hrmdi:o:" O; do
	case "$O" in
		h) usage; exit ;;
		r) RECURSIVE='*' ;;
		m) OPERATION="mv" ;;
		d) DESTRUCTIVE="true" ;;
		i) IDIR=$OPTARG ;;
		o) ODIR=$OPTARG ;;
		*) echo -e "${RED}Invalid option encoutered: \"$O\". Exiting.${NORMAL}"; usage; exit 1 ;;
	esac
done

shopt -s globstar

STDGLOB='*'$RECURSIVE

for i in "$IDIR/"${STDGLOB}; do
	[ -d "$i" ] && continue
	MIME=$(file --mime-type "$i" | cut -d ":" -f 2 | cut -d "/" -f 2)
	! [ -d ${ODIR}/${MIME} ] && mkdir "${ODIR}/${MIME}"
	${OPERATION} "$i" "${ODIR}/${MIME}/"
done

[ -n "$DESTRUCTIVE" ] && rm -d $IDIR/*
