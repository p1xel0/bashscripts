#!/bin/bash
##
# Extremly buggy and unclean code for splitting singular chapter files from BDMV sources
# Video input is not configurable script expects sources to be mp4 encodes of m2ts from BDMV i.e. 00001.mp4
# Source chapter file in XML format is required
# This script works by using ffprobe to get the length of each video and accumulating this total in a loop
# and splitting based on the closest timestamp to the total runtime while still being less than the total runtime
# This script expects that your source has a chapter realtively close to the end of each video
# Usage: ./path_of_script /path/to/chapters.xml
##
if [ -z "$1" ]; then
	echo "error: no xml input" && exit 1
elif [ -d "$1" ]; then
	echo "error: input is a directory" && exit 1
elif [ ! -f "$1" ]; then
	echo "error: input does not exist" && exit 1
elif [ -z "$(echo "$1" | grep xml$)" ]; then
	echo "error: input is not an xml file" && exit 1
elif [ -z "$(cat "$1" | grep matroskachapters.dtd)" ]; then
	echo "error: input is not a matroska chapter file"
fi
function sex2sec(){
	if ! echo "$1" | grep -q ^[0-9].*\:[0-9].*\:[0-9].*\.[0-9]$; then
		echo "error: not sexagesimal input"
	fi
	time="$1"
	hour="${time%%:*}" && hour="${hour#0}" && hour=$(( hour * 3600 ))	
	min="${time#*:}" && min="${min%:*}" && min="${min#0}" && min=$(( min * 60 ))
	sec="${time##*:}"
	total=$(echo "$hour+$min+$sec" | bc)
	echo "$total"
}
time_total=0
mapfile -t chap_tcodes < <( grep ChapterTimeStart "$1" | grep -o [0-9].*\:[0-9].*\:[0-9].*\.[0-9] )
for ((i=0;i<"${#chap_tcodes[@]}";i++)); do
	chap+=( "$(sex2sec "${chap_tcodes[$i]}")" )
done
mapfile -t in_files < <(ls [0-9][0-9][0-9][0-9][0-9].mp4)
for ((i=0;i<"${#in_files[@]}";i++)); do
	dur="$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 -sexagesimal "${in_files[$i]}")"
	if [ -z "$dur" ]; then
		echo "error: '"${in_files[$i]}"' is not a valid media file"
		exit 1
	fi
	total=$(sex2sec "$dur")
	time_total=$(echo "$time_total+$total" | bc)
	tdur+=("$time_total")
done
unset 'tdur[-1]'
for ((i=0;i<"${#tdur[@]}";i++)); do
	temp_array=("${chap[@]}")
	temp_array+=("${tdur[$i]}")
	chap_start=$(printf '%s\n' "${temp_array[@]}" | sort -n | grep -n -B1 "${tdur[$i]}" | head -1 | grep -o -- ^[0-9].*-)
	chap_start=${chap_start::-1}
	chapter_name=$(printf "%02d" "$chap_start")
	chap_end=$(grep -B4 -n 'Chapter '"$chapter_name" "$1" | head -1 | grep -o -- ^[0-9].*-)
	chap_end=${chap_end::-1}
	chap_ends+=("$chap_end")
done
lcount="$(cat "$1" | wc -l)"
lcount=$((lcount+1))
chap_ends+=("$lcount")
for ((i=0;i<"${#chap_ends[@]}";i++)); do
	out="${in_files[$i]}"
	out="${out%.*}"
	cur="$(( ${chap_ends[$i]} - 1 ))"
	if [ $i -eq 0 ]; then
		sed -n 1,"$cur"p "$1" > "$out".xml
		tail -2 "$1" >> "$out".xml
		last="${chap_ends[$i]}"
		continue
	fi
	header="$(grep -n EditionUID "$1")"
	header="${header%%:*}"
	head -"$header" "$1" > "$out".xml || exit 1
	sed -n "$last","$cur"p "$1" >> "$out".xml
	if [ -n "$(tail -1 "$out".xml | grep '</Chapters>')" ]; then
		continue
	fi
	tail -2 "$1" >> "$out".xml
	last="${chap_ends[$i]}"
done
for ((i=0;i<"${#in_files[@]}";i++)); do
	out="${in_files[$i]}"
	out="${out%.*}"
	chapnum="$(grep '<ChapterString>' "$out".xml | grep -o '[0-9][0-9]' | head -1)"
	chapnum="${chapnum#0}"
	chapnum="$(( chapnum - 1 ))"
	mapfile -t chapnums < <(grep '<ChapterString>' "$out".xml | grep -o '[0-9][0-9]')
	for ((d=0;d<"${#chapnums[@]}";d++)); do
		chapval="${chapnums[$d]}"
		chapval="${chapval#0}"
		chapval=$(( "$chapval" - "$chapnum" ))
		while [ "${#chapval}" -lt 2 ]; do
			chapval=0"$chapval"
		done
		sed -i "s/<ChapterString>Chapter ${chapnums[$d]}<\/ChapterString>/<ChapterString>Chapter $chapval<\/ChapterString>/" "$out".xml
	done
	# b = base, c = current, d = diff, f = final
	btime="$(grep '<ChapterTimeStart>' "$out".xml | grep -o [0-9:.].*[0-9] | head -1)"
	bhour="${btime%%:*}" && bhour="${bhour#0}" && bhour=$(( bhour * 3600 ))
	bmin="${btime#*:}" && bmin="${bmin%:*}" && bmin="${bmin#0}" && bmin=$(( bmin * 60 ))
	bsec="${btime##*:}"
	bsecs=$(echo "$bhour+$bmin+$bsec" | bc)
	mapfile -t chaptime < <(grep '<ChapterTimeStart>' "$out".xml | grep -o [0-9:.].*[0-9])
	for ((f=0;f<"${#chaptime[@]}";f++)); do
	       ctime="${chaptime[$f]}"
        	chour="${ctime%%:*}" && chour="${chour#0}" && chour=$(( chour * 3600 ))
        	cmin="${ctime#*:}" && cmin="${cmin%:*}" && cmin="${cmin#0}" && cmin=$(( cmin * 60 ))
        	csec="${ctime##*:}"
        	csecs=$(echo "$chour+$cmin+$csec" | bc)
		dsecs=$(echo "$csecs - $bsecs" | bc)
		fms="${dsecs##*.}"
		while [ "${#fms}" -lt 9 ]; do
			fms="$fms"0
		done
		fsecs="${dsecs%.*}"
		fhour=$(( fsecs / 3600 )) && fhour=$(printf "%02d" $fhour)
		fmin=$(( ( fsecs / 60 ) % 60 )) && fmin=$(printf "%02d" $fmin)
		fsecs=$(( fsecs % 60 )) && fsecs=$(printf "%02d" $fsecs)
		ftime="$fhour:$fmin:$fsecs.$fms"
		sed -i "s/<ChapterTimeStart>${chaptime[$f]}<\/ChapterTimeStart>/<ChapterTimeStart>$ftime<\/ChapterTimeStart>/" "$out".xml
	done
done
