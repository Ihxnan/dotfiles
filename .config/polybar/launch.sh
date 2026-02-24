#!/usr/bin/env bash

killall polybar || true

while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

if type "xrandr"; then
    for m in $(polybar --list-monitors | cut -d":" -f1); do
        MONITOR=$m polybar top -c $HOME/.config/polybar/nord/config-top.ini &
    done
else
    polybar top -c $HOME/.config/polybar/nord/config-top.ini &
fi
