#!/bin/bash
vcodec="DIV3"
w="740"
h="480"
acodec="mp4a"
bitrate="128"
arate="192"
ext="avi"
mux="avi"
vlc="/Applications/VLC.app/Contents/MacOS/VLC"
fmt="MPG"

for a in *$fmt; do 
	$vlc -I dummy -vvv "$a" --sout "#transcode{vcodec=$vcodec,width=$w,height=$h,vb=$bitrate,channels=6}:standard{mux=$mux,dst=\"$a.$ext\",access=file}" vlc://quit 

done

