#!/bin/bash
# qute-reload.sh - reload qutebrowser's config after matugen regenerated the
# wallpaper-derived theme colors.
#
# Called from matugen's post_hook (see ~/.config/matugen/config.toml).
# Does nothing when no qutebrowser instance is running, so it can never
# spawn a stray window.
# @author nate zhou
# @since 2026
# @depends qutebrowser, coreutils

set -u

# qutebrowser renames its own process to "qutebrowser", so -x matches the
# process name exactly. Deliberately NOT `pgrep -f`: -f matches the whole
# command line, and this script's own command line contains the string
# "qutebrowser", which made pgrep report a false positive.
pgrep -x qutebrowser >/dev/null 2>&1 || exit 0

# Fire-and-forget: never block a matugen run. The command only tells the
# running instance to re-source its config.py (which re-sources the generated
# matugen_colors.py).
timeout 5 qutebrowser ':config-source' >/dev/null 2>&1 &

exit 0
