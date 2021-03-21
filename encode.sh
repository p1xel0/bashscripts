#!/bin/bash
## 
# Wrapper script for encoding animated sources using x265 and ffmpeg with high bitrate params
# Usage: ./path_of_script.sh source_file(s) 
##
args=("$@")
if pidof -x "$(basename "$0")" -o $$ > /dev/null; then
        echo -e "\033[1m\033[31merror: another instance is already running\033[0m" && exit 1
elif [ "${#args[@]}" -eq 0 ]; then
	echo -e "\033[1m\033[31merror: no input file(s)\033[0m" && exit 1
fi
startsec="$(date +%s)"
for ((i=0;i<"${#args[@]}";i++)); do
	if [ -d "${args[$i]}" ]; then
		echo -e "\033[1m\033[31merror: '${args[$i]}' is a directory\033[0m" && continue
	elif [ ! -f "${args[$i]}" ]; then
		echo -e "\033[1m\033[31merror: '${args[$i]}' does not exist\033[0m" && continue
	elif ! mediainfo "${args[$i]}" | grep -q ^Height; then
		echo -e "\033[1m\033[31merror: '${args[$i]}' does not contain a video stream\033[0m" && continue
	fi
	base="$(basename "${args[$i]}")"
	base="${base%.*}"
	if [ -f ~/Videos/"$base".mp4 ]; then
		echo -e "\033[1m\033[31merror: output file '~/Videos/$base.mp4' already exists\033[0m" && continue
	fi
	ffmpeg -i "${args[$i]}" -c:v libx265 -preset slow -crf 15 -x265-params 'sao=no:strong-intra-smoothing=no:bframes=8:psy-rd=1.5:psy-rdoq=4:aq-mode=3:deblock=-1,-1' -pix_fmt yuv420p10le -sn -an -nostdin -map_metadata -1 -map_chapters -1 -loglevel 8 -stats -- ~/Videos/"$base".mp4 || exit
done
endsec="$(date +%s)"
diffsec=$(( endsec - startsec ))
diffhour=$(( diffsec / 3600 )) && diffhour=$(printf "%02d" $diffhour)
diffmin=$(( ( diffsec / 60 ) % 60 )) && diffmin=$(printf "%02d" $diffmin)
diffsec=$(( diffsec % 60 )) && diffsec=$(printf "%02d" $diffsec)
echo "encode took: $diffhour:$diffmin:$diffsec"
