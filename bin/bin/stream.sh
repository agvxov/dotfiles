#!/bin/bash
# Stream your screen over the network. 
ffmpeg \
    -hide_banner \
    -loglevel error \
    -fflags nobuffer \
    -avioflags direct \
    -use_wallclock_as_timestamps 1 \
    -thread_queue_size 64 \
    -probesize 32 \
    -analyzeduration 0 \
    -f x11grab \
    -draw_mouse 0 \
    -framerate 30 \
    -video_size 1920x1080 \
    -i :0.0+0,0 \
    -fps_mode passthrough \
    -c:v libx264 \
    -preset ultrafast \
    -tune zerolatency \
    -g 30 \
    -b:v 8M -maxrate 10M \
    -bufsize 10M \
    -pix_fmt yuv420p \
    -bsf:v h264_mp4toannexb \
    -flush_packets 1 \
    -max_interleave_delta 0 \
    -muxdelay 0 \
    -muxpreload 0 \
    -mpegts_flags resend_headers \
    -flags +low_delay \
    -f mpegts \
    "srt://10.8.0.101:8697/?mode=caller"
# XXX: hardcoded address of Emil/OVPN.
