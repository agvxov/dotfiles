#!/bin/bash

function help() {
	echo "$0 ([options]) [file]"
	echo "    -h : show this very message"
	echo "    -d : directory; [file] shall be a folder"
	echo "    -r : recursive; if used without '-d', the script exits with 2"
	exit 0
}

if [ -z $1 ]; then
	echo "Invalid use."
	exit 1
fi

directory="false"
recursive="false"

for i in $@; do
	if [ $i == "-h" ] || [ $i == "--help" ]; then
		help
	fi
	if [ $i == "-d" ]; then
		directory="true"
	fi
	if [ $i == "-r" ]; then
		recursive="true"
	fi
done

if [ $directory == "true" ]; then
	if ! [ -d ${@: -1} ]; then
		"Option '-d' was specified but the last argument is not a directory."
		exit 1
	fi
	cd ${@: -1}

	if [ $recursive  == "true" ]; then
		shopt -s globstar
		for i in **; do
			if [ -d $i ]; then
				continue
			fi
			name=$(mediainfo $i | grep "Movie name")
			if [ -n name ]; then
				name=${name##*:}
				name=${name// /_}
				name="$(dirname "$i")/$name"
				echo -n "$i -> "
				echo $name
				mv $i $name
			fi
		done
	else
		for i in *; do
			if [ -d $i ]; then
				continue
			fi
			name=$(mediainfo $i | grep "Movie name")
			if [ -n name ]; then
				name=${name##*:}
				name=${name// /_}
				echo -n "$i -> "
				echo $name
				mv $i $name
			fi
		done
	fi
else
	if [ $recursive == "true" ]; then
		exit 2
	fi
	name=${@: -1}
	name=${name%%/*}
	cd $name
	name=${@: -1}
	name=${name##*/}
	if [ -d $i ]; then
		echo "A directory was specified without the '-d' options."
		exit 1
	fi
	real_name=$(mediainfo $name | grep "Movie name")
	if [ -n real_name ]; then
		real_name=${real_name##*:}
		real_name=${real_name// /_}
		echo -n "$name -> "
		echo $real_name
		mv $name $real_name
	fi
fi
