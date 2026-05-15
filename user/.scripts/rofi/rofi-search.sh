#!/bin/bash

SEARCH_ENGINE="https://www.google.com/search?q="

query=$(rofi -dmenu \
    -p "Search " \
    -lines 0 \
    -theme material \
    -font "hack 20" \
    -show-icons)

if [ -n "$query" ]; then
    encoded_query=$(echo "$query" | sed 's/ /+/g')
    xdg-open "${SEARCH_ENGINE}${encoded_query}"
fi
