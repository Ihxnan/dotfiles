#!/usr/bin/env bash

export DISPLAY=:0
export XAUTHORITY=$HOME/.Xauthority
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus

WALLPAPER_DIR=$HOME/.wallpapers

FEH_MODE=--bg-fill

WALLPAPER_LIST=($(ls -1 "$WALLPAPER_DIR"/* 2>/dev/null | grep -E "\.(jpg|jpeg|png|gif|bmp|webp)$" | sort -R))

RANDOM_INDEX=$((RANDOM % ${#WALLPAPER_LIST[@]}))

CURRENT_WALLPAPER="${WALLPAPER_LIST[$RANDOM_INDEX]}"

feh $FEH_MODE "$CURRENT_WALLPAPER"

matugen image "$CURRENT_WALLPAPER"

bash /home/ihxnan/.scripts/fcitx5/reload.sh
