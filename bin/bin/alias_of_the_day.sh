#!/bin/bash

# Search for $(alias)s in a directory of bash files
# Choose one and save it with current date
# Repeat only on its a new day

# Meant to be used for composing a $(watch) screen

shopt -s globstar

SAVEFILE="/home/anon/stow/.cache/aotd.data"
BASHRCDIR="/home/anon/stow/bash/"

function print_aotd(){
	echo -e "\033[1;33mAlias of the day:\033[0m \033[34m"$1"\033[0m"
}

function draw_new(){
	date +"%d" > "$SAVEFILE"
	cat $(find "${BASHRCDIR}" -type f -print) | egrep -h "^\s*alias"  | shuf | head -1 | cut -d ' ' -f 2- | cut -d '#' -f 1 >> "$SAVEFILE"
}

DATADATE="$(sed --silent "1p" "${SAVEFILE}")"
[ "$DATADATE" == "" ] || [ "$DATADATE" != "$(date +"%d")" ] && draw_new


print_aotd "$(sed --silent "2p" "$SAVEFILE")"
