#!/usr/bin/env bash

if pgrep -x "mpd" > /dev/null; then
    mpc toggle
fi

if pgrep -x "spotify" > /dev/null; then
    playerctl -p spotify play-pause
fi
