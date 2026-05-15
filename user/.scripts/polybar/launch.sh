#!/usr/bin/env bash

killall polybar || true

while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

PRIMARY_MONITOR="eDP-1"
SECONDARY_MONITOR="HDMI-1-0"

if type "xrandr"; then
    for m in $(polybar --list-monitors | cut -d":" -f1); do
        if [ "$m" = "$PRIMARY_MONITOR" ]; then
            MONITOR=$m polybar eDP -c $HOME/.config/polybar/nord/config-eDP.ini &
        elif [ "$m" = "$SECONDARY_MONITOR" ]; then
            MONITOR=$m polybar HDMI -c $HOME/.config/polybar/nord/config-HDMI.ini &
        else
            MONITOR=$m polybar top -c $HOME/.config/polybar/nord/config-top.ini &
        fi
    done
else
    polybar top -c $HOME/.config/polybar/nord/config-top.ini &
fi
