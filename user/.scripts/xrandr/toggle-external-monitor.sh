#!/usr/bin/env bash

MONITOR="HDMI-1-0"
MAIN_MONITOR="eDP-1"

ACTIVE_STATUS=$(xrandr | grep "$MONITOR connected" | grep -oP '\d+x\d+')

if [ -z "$ACTIVE_STATUS" ]; then
    xrandr --output "$MAIN_MONITOR" --primary --auto --output "$MONITOR" --auto --right-of "$MAIN_MONITOR"
else
    xrandr --output "$MAIN_MONITOR" --primary --auto --output "$MONITOR" --off
fi

sleep 2
$HOME/.scripts/polybar/launch.sh
$HOME/.scripts/feh/random_feh.sh
