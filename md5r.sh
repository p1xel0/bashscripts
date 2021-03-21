#!/bin/bash
##
# Recursive md5sum wrapper script
# This script was made for keeping a running md5 of my media files in the event I swap drives
# This script is only designed for STATIC files it does not take into account mod times
# Usage: ./path_of_script /path/to/dir
##
if [ -z "$1" ]; then
	echo "error: no input directory" && exit
elif [ -f "$1" ]; then
	echo "error: input directory is a file" && exit
elif [ ! -d "$1" ]; then
	echo "error: input directory does not exist" && exit
else
	cd "$1" || exit 1
	trap 'rm -f ./.md5files.txt ./.files.txt' 1 2 3 6 14 15
	find . -type f | sort | grep -v "./md5.txt\|./.files.txt\|./.md5files.txt" > ./.files.txt
	if [ -f "$1"/md5.txt ]; then
		cut -c 35- ./md5.txt > ./.md5files.txt
		diff -q ./.md5files.txt ./.files.txt &> /dev/null && exit 1
		mapfile -t deleted_files < <( diff ./.md5files.txt ./.files.txt | grep \< | sed "s/^..//;s|/|\\\/|g;s|\\[|\\\[|g" )
		for ((i=0;i<"${#deleted_files[@]}";i++)); do
			sed -i "/  ${deleted_files[$i]}$/d" ./md5.txt
		done
		mapfile -t new_files < <( diff ./.md5files.txt ./.files.txt | grep \> | sed 's/..//' )
	else
		mapfile -t new_files < <( find . -type f | sort )	
	fi
	total="${#new_files[@]}"
	pad_len="${#total}"
	for ((i=0;i<"${#new_files[@]}";i++)); do
		cur="$((i+1))"
		while [ "${#cur}" != "$pad_len" ]; do
			cur="0$cur"
		done
		echo -ne "$cur/$total\t${new_files[$i]}"
		md5sum "${new_files[$i]}" >> ./md5.txt || exit 1
		echo
	done
	sort -k 2.1 -o ./md5.txt ./md5.txt
	rm -f ./.md5files.txt ./.files.txt
fi	
