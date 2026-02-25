#!/bin/bash

TT_HIGH_SCORE_FILE="${HOME}/.ttscore"

[ -e "$TT_HIGH_SCORE_FILE" ] || printf "0\n0" > "$TT_HIGH_SCORE_FILE"

LINE="$(tt -t 60 -bold -n 120 -g 120 -nobackspace -noskip -oneshot -csv -blockcursor -theme slate | head -n 1)"
SCORE="$(echo ${LINE} | cut -d, -f2)"
ACCURACY="$(echo ${LINE} | cut -d, -f4)"

OSCORE="$(cat "${TT_HIGH_SCORE_FILE}" | head -n 1)"
OACCURACY="$(cat "${TT_HIGH_SCORE_FILE}" | head -n 2 | tail -n 1)"

echo "Score and accuracy: ${SCORE}; ${ACCURACY}" 
echo "Previous high score and accuracy: ${OSCORE}; ${OACCURACY}"

if (( $(echo "${ACCURACY} > 90.0" | bc -l) )) && (( $SCORE > $OSCORE )); then
	enable -n echo
	echo -e "\33[1;32mCongratulations (you) have reached a new high score!\33[0m"
    echo $SCORE $ACCURACY
	echo $SCORE > "${TT_HIGH_SCORE_FILE}"
	echo $ACCURACY >> "${TT_HIGH_SCORE_FILE}"
fi
