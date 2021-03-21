#!/bin/bash
##
# Script for adjusting brightness of multiple monitors without a daemon using xrandr 
# Usage: ./path_of_scipt [up,down]  
# 'up' increase brightness by 10% 
# 'down' decrease brightness by 10%
##
if pidof -x "$(basename "$0")" -o $$ > /dev/null; then
	exit 0
fi
mapfile -t displays < <( xrandr -q | grep ' connected' | awk '{ print $1 }' )
for ((i=0;i<"${#displays[@]}";i++)); do
	cur_brightness=$(xrandr --verbose --current | grep -A5 -- "${displays[$i]}" | awk '/Brightness:/{ print $2 }')
	if [ "$1" = "up" ]; then
		if [ "$cur_brightness" = '1.0' ]; then
			break
		fi
		set_brightness=$(echo "$cur_brightness"'+0.1' | bc)
	elif [ "$1" = "down" ]; then
		if [ "$cur_brightness" = '0.10' ]; then
			break
		fi
		set_brightness=$(echo "$cur_brightness"'-0.1' | bc)
	else
		break
	fi
	xrandr --output "${displays[$i]}" --brightness "$set_brightness"
done
if [ -n "$set_brightness" ]; then
	cur_brightness="$(echo "$set_brightness"*100 | bc)"
else
	cur_brightness="$(echo "$cur_brightness"*100 | bc)"
fi
cur_brightness=${cur_brightness%.*}
for ((i=0;i<"${cur_brightness:: -1}";i++)); do
	slider+="█"
done
while [ "${#slider}" -lt 10 ]; do
	slider+="─"
done
notify-send.sh -i weather-clear -t 1000 -h string:synchronous:brightness -f "Brightness: $cur_brightness% │$slider│"
