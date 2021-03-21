#!/bin/bash
##
# Script for automatically downloading SubsPlease releases from rclone remote using a TUI dialog
# Intended to be used alongside an instance of https://github.com/p1xel0/SubsPlease-AdRu
##
if pidof -x "$(basename "$0")" -o $$ > /dev/null; then
	echo -e "\033[1m\033[31merror: another instance is already running\033[0m" && exit 1
fi
IFS=$'\n'
mapfile -t names < <(wget -qO- 'https://subsplease.org/rss/?t&r=1080' | sed 's/<link>/\n/g' | grep -o '<title>.*</title>' | tail -n +2 | sed 's/^<title>//;s/<\/title>$//;s/&amp;/\x26/g;s/&apos;/\x27/g')
unset IFS
if [ -z "${names[0]}" ]; then
	echo -e "\033[1m\033[31merror: failed to retrieve SubsPlease RSS\033[0m" && exit 1	
fi
MENU_OPTIONS=
COUNT=0
for ((i=0;i<"${#names[@]}";i++)); do
	COUNT=$((COUNT+1))
	name="${names[$i]}"
	name="${name/\'/\'\\\'\'}"
	MENU_OPTIONS="$(echo -ne "$MENU_OPTIONS" "$COUNT" \\x27$name\\x27 off )"
done
#This magically breaks without xargs ¯\_(ツ)_/¯
choices=$(echo '--separate-output --no-shadow --no-lines --checklist --output-fd 1 "SubsPlease RSS:" 99999 99999 99999 '"$MENU_OPTIONS" | xargs dialog)
clear
for choice in $choices; do
	i=$((choice-1))
	dir="${names[$i]}"
	dir="${dir:13}"
	dir="${dir% - *}"
	mkdir -p ~/Downloads/HorribleSubs/"$dir"
	rclone copy --progress --ignore-existing drive:/HorribleSubs/"$dir"/"${names[$i]}" ~/Downloads/HorribleSubs/"$dir"/ 
done
