#!/bin/bash
##
# Wrapper script for my assfc fork to automagically attach fonts 
# to a maktroska container without remuxing using mkvpropedit
# 
# assfc_path = path to assfc.py (avaliable at https://github.com/p1xel0/assfc) 
# font_path = folder assfc should use when looking for fonts
##
assfc_path=~/Downloads/assfc/assfc.py
font_path=~/.fonts/

files=("$@")
if pidof -x "$(basename "$0")" -o $$ > /dev/null; then
        echo -e "\033[1m\033[31merror: another instance is already running\033[0m" 1>&2 && exit 1
elif [ "${#files[@]}" -eq 0 ]; then
	echo -e "\033[1m\033[31merror: no input file(s)\033[0m" 1>&2 && exit 1
fi
for ((i=0;i<"${#files[@]}";i++)); do
	if [ -d "${files[$i]}" ]; then
		echo -e "\033[1m\033[31merror: '${files[$i]}' is a directory\033[0m" 1>&2 && continue
	elif [ ! -f "${files[$i]}" ]; then
		echo -e "\033[1m\033[31merror: '${files[$i]}' does not exist\033[0m" 1>&2 && continue
	fi
	ffmpeg -y -i "${files[$i]}" -loglevel quiet -map 0:s:0 -c copy "${files[$i]}".ass || { echo -e "\033[1m\033[31merror: '${files[$i]}' does not contain subtitles\033[0m" 1>&2; continue; }
	mapfile -t fonts < <("$assfc_path" --include "$font_path" "${files[$i]}".ass)
	if [ "${#fonts[@]}" -eq 0 ]; then
		echo -e "\033[1m\033[31merror: failed to find font(s) for '${files[$i]}'\033[0m" 1>&2
		rm "${files[$i]}".ass
		exit 1
	else
		if mediainfo "${files[$i]}" | grep -q ^Attachments; then
			mkvpropedit "${files[$i]}" --delete-attachment mime-type:application/x-truetype-font --delete-attachment mime-type:application/vnd.ms-opentype
		fi
	fi
	esc_file="$(printf '%q' "${files[$i]}")"
	echo "$esc_file" "$(for f in "${fonts[@]}"; do suffix="${f##*.}" && if [ "${suffix,,}" = otf ]; then mime='application/vnd.ms-opentype'; else mime='application/x-truetype-font'; fi && esc_font="$(printf '%q' "$f")" && echo -n '--attachment-mime-type '"$mime"' --add-attachment '"$esc_font "; done)" | xargs mkvpropedit
	rm "${files[$i]}".ass
done
