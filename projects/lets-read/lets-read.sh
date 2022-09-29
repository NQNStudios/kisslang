#! /bin/bash
# Usage: lets-read.sh <youtube url> <output file without extension> <optional scene change threshold>

if [ ! -e ${2}.mp4 ]; then
    youtube-dl $1 -o $2
    if [ -e "${2}.mkv" ]; then
        ffmpeg -i ${2}.mkv -codec copy ${2}.mp4
        rm "${2}.mkv"
    elif [ -e "${2}.webm" ]; then
        ffmpeg -i ${2}.webm ${2}.mp4
        rm "${2}.webm"
    fi
fi

threshold=${3:-1} # default 1 fps

if [ ! -d ${2} ]; then
    mkdir ${2}
fi

ffmpeg -i ${2}.mp4 -vf "fps=${threshold}" -vsync vfr ${2}/frame-%6d.jpg

rm ${2}/*.txt

haxelib run lets-read ${2}
convert ${2}/frame-*.jpg ${2}.pdf

# rm ${2}/frame-*.jpg