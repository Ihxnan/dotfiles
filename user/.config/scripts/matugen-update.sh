#!/bin/bash
set -euo pipefail

WALL="$1"
[ -z "$WALL" ] && exit 1

# Generate all Material You themes (yazi, btop, fcitx5, etc.)
matugen image -c "$HOME/.config/matugen/config.toml" "$WALL" --prefer darkness -q 2>/dev/null || true

# Notify running yazi to restart with new theme
YAZI_PID=$(pgrep -x yazi | head -1)
if [ -n "$YAZI_PID" ]; then
    YAZI_ID=$(tr '\0' '\n' < "/proc/$YAZI_PID/environ" 2>/dev/null | grep ^YAZI_ID= | cut -d= -f2)
    if [ -n "$YAZI_ID" ]; then
        touch /tmp/yazi-restart-flag
        timeout 3 ya emit-to "$YAZI_ID" quit 2>/dev/null || true
    fi
fi
