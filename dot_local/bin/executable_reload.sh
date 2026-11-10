#!/bin/bash
SCREEN_NAME="blog"

screen -S "$SCREEN_NAME" -X stuff $'\003'

screen -S "$SCREEN_NAME" -X stuff "pnpm build\n"

screen -S "$SCREEN_NAME" -X stuff "pnpm preview --host\n"
