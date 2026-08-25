#!/bin/bash

xset s off

# i milliseconds delay; h repeats per second
xset r rate 140 55

setxkbmap -layout hu,ru -variant nodeadkeys,phonetic -option grp:alt_caps_toggle
setxkbmap -option caps:swapescape
