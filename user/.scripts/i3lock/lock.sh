#!/bin/bash

BLANK='#00000000'
CLEAR='#ffffff22'
DEFAULT='#cdb0eecc'
TEXT='#f48484ee'
WRONG='#880000bb'
VERIFYING='#bb00bbbb'

i3lock \
    --insidever-color=$CLEAR \
    --ringver-color=$VERIFYING \
    \
    --insidewrong-color=$CLEAR \
    --ringwrong-color=$WRONG \
    \
    --inside-color=$BLANK \
    --ring-color=$DEFAULT \
    --line-color=$BLANK \
    --separator-color=$DEFAULT \
    \
    --verif-color=$TEXT \
    --wrong-color=#ff0000 \
    --time-color=$TEXT \
    --date-color=#a5c689 \
    --layout-color=$TEXT \
    --keyhl-color=$WRONG \
    --bshl-color=$WRONG \
    \
    --screen 1 \
    --blur 5 \
    --clock \
    --force-clock \
    --indicator \
    --time-str="%H:%M:%S" \
    --time-size=128 \
    --date-str="%A  %Y-%m-%d" \
    --date-size=30 \
    --wrong-size=60 \
    --verif-size=60 \
    --radius=300 \
    --pointer default \
    --show-failed-attempts
# --keylayout 1                \
# --time-font="Monaco"        \

xdotool mousemove_relative 1 1 # This command solves the issue where lock screen is not displayed after auto-lock (moves the mouse)
