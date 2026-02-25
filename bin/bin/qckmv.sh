#!/bin/bash
# For each image, ask what subdirectory of PWD it should be moved to.

declare -a ITEMS
for i in *.jpg *.png; do
	ITEMS+=($i)
done
IFSBAK="$IFS"
IFS=$'\n'
ITEMS=($(sort <<<"${ITEMS[*]}"))
IFS="$IFSBAK"

declare -a DIRS
for i in $(find ./ -type d); do
	DIRS+=($i)
done

while [ -n "${ITEMS}" ]; do
	echo ${ITEMS}:
	nomacs ${ITEMS} &> /dev/null &
	sleep 0.5; xdotool click 1
	h=1
	for i in ${DIRS[*]}; do
		echo " ${h}) ${i}"
		h=$(expr $h + 1)
	done
	read choise
	h=1
	for i in ${DIRS[*]}; do
		(( $choise == $h )) && mv ${ITEMS} $i/ && break
		h=$(expr $h + 1)
	done
	kill $(jobs -p)
	ITEMS=(${ITEMS[@]:1})
done
