#!/bin/bash

shopt -s globstar

SAVEFILE="/home/anon/stow/.data/nev_nap.data"
NEVNAPJSON="/home/anon/stow/.data/nev_napok.json"

function draw_new(){
	cat "$NEVNAPJSON" | jq .[\"$(date +'%d-%m')\"] > "$SAVEFILE"
}

[ "$DATADATE" == "" ] || [ "$DATADATE" != "$(date +"%d")" ] && draw_new

echo -e "\033[1;33mName days:\033[0m"
cat "$SAVEFILE" | jq -C
