#/usr/bin/env bash

for SOCKET in /tmp/kitty-*.socket-*; do
    if [ -S "$SOCKET" ]; then
        kitty @ --to "unix:$SOCKET" load-config
    fi
done
