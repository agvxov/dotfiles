#!/bin/sh
# png-squeeze.sh FILE...

set -eu

while [ "$#" -gt 0 ]; do
    magick "$1" -despeckle png:- | pngquant -o "$1".squeezed -
    mv "$1".squeezed "$1"
    shift
done
