#!/bin/sh

usage() {
    echo 'git-phonebook [--help] URL'
}

if [ "$#" -ne 1 ]; then
    usage
    exit 1
fi

case "$1" in
    help|--help|-h)
        usage
        exit 0
        ;;
esac

url=$1
tempdir=$(mktemp -d "${TMPDIR:-/tmp}/git-phonebook.XXXXXX") || exit 1

cleanup() {
    rm -rf "$tempdir"
}

trap cleanup 0 1 2 15

cd "$tempdir" || exit 1
git clone --quiet --no-checkout "$url" . || exit 1

git log --format='%cn <%ce>' |
sort |
uniq --count |
sort -nr
