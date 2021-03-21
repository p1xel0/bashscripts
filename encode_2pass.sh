#!/bin/bash
## 
# Wrapper script for encoding movie sources using x264 and ffmpeg with a high-bitrate 2 pass 
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
	ffmpeg -y -i "${args[$i]}" -c:v libx264 -pass 1 -preset veryslow -x264-params 'ref=4:subme=9:me_range=16:threads=12:lookahead_threads=1:slices=4:bframes=3:b_pyramid=0:b_adapt=1:weightp=1:keyint=24:keyint_min=1:rc_lookahead=24:bitrate=14020:ratetol=1.0:cplxblur=20.0:qblur=0.5:vbv_maxrate=30000:vbv_bufsize=30000:nal_hrd=vbr:filler=0:ipratio=1.10' -sn -an -pix_fmt yuv420p10le -profile:v high10 -map_chapters -1 -map_metadata -1 -nostdin -f mp4 /dev/null && \
	ffmpeg -i "${args[$i]}" -c:v libx264 -pass 2 -preset veryslow -x264-params 'ref=4:subme=9:me_range=16:threads=12:lookahead_threads=1:slices=4:bframes=3:b_pyramid=0:b_adapt=1:weightp=1:keyint=24:keyint_min=1:rc_lookahead=24:bitrate=14020:ratetol=1.0:cplxblur=20.0:qblur=0.5:vbv_maxrate=30000:vbv_bufsize=30000:nal_hrd=vbr:filler=0:ipratio=1.10' -sn -an -pix_fmt yuv420p10le -profile:v high10 -map_chapters -1 -map_metadata -1 -nostdin -- ~/Videos/"$base".mp4
done
rm -f ./ffmpeg2pass-0.log
rm -f ./ffmpeg2pass-0.log.mbtree
endsec="$(date +%s)"
diffsec=$(( endsec - startsec ))
diffhour=$(( diffsec / 3600 )) && diffhour=$(printf "%02d" $diffhour)
diffmin=$(( ( diffsec / 60 ) % 60 )) && diffmin=$(printf "%02d" $diffmin)
diffsec=$(( diffsec % 60 )) && diffsec=$(printf "%02d" $diffsec)
echo "encode took: $diffhour:$diffmin:$diffsec"
