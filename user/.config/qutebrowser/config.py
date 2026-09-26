# vim:ft=python
# qutebrowser/config.py
# @author nate zhou
# @since 2025,2026

c.zoom.default = 120

config.source('proxy.py')
config.source('matugen_colors.py')
config.source('bindings.py')
config.source('search.py')

# Disabled together with forced dark mode (see colors.py). black.css forces
# html/body to #111111 !important, which leaves light-themed pages with dark
# text on a near-black backdrop once forced dark mode is off. It also cannot be
# limited to selected sites (content.user_stylesheets takes no URL pattern).
# c.content.user_stylesheets = ["~/.config/qutebrowser/styles/black.css"]

config.load_autoconfig(False) # ignore GUI settings

import os
import shlex

if os.environ.get('XDG_SESSION_TYPE') == 'wayland':
    term = 'footclient -T Floating_Term -o colors.alpha=0.9'
else:
    term = 'st -T Floating_Term'

c.editor.command = shlex.split(term) + \
        ['nvim', '{file}', '-c', 'normal {line}G{column0}l']

fileChooser = shlex.split(term) + ['lf', '-selection-path={}']
c.fileselect.handler = "external"
c.fileselect.folder.command = fileChooser
c.fileselect.multiple_files.command = fileChooser
c.fileselect.single_file.command = fileChooser

c.url.start_pages = 'file:///dev/null'
c.url.default_page= 'file:///dev/null'
c.tabs.last_close = "startpage"
c.auto_save.session = True

c.zoom.levels = ["25%", "33%", "50%", "67%", "75%", "90%", "100%", "110%", "120%", "130%", "140%", "150%", "175%", "200%", "250%", "300%"]

# JetBrains Maple Mono for the whole browser: UI, hints and web content. It is
# a monospace font (JetBrains Mono + Maple Mono, Nerd Font patched) covering
# U+4E00-U+9FEF, so ordinary Chinese text renders fine; the rare glyphs it
# lacks (CJK Ext-A/B) are the only ones that need a fallback.
# The UI settings take a comma-separated family list, so Noto Sans CJK SC is
# listed explicitly. The web settings are passed verbatim as one family name to
# QWebEngineSettings.setFontFamily (a comma-separated list there is taken as a
# single, non-existent family name and silently falls back to the default
# font), so only the family itself is set and missing glyphs are resolved by
# fontconfig (Noto Sans CJK SC on this system).
c.fonts.default_family = 'JetBrains Maple Mono, Noto Sans CJK SC' # UI
c.fonts.default_size = '13pt'
c.fonts.web.family.standard = 'JetBrains Maple Mono'
c.fonts.web.family.sans_serif = 'JetBrains Maple Mono'
c.fonts.web.family.serif = 'JetBrains Maple Mono'
c.fonts.web.family.fixed = 'JetBrains Maple Mono'
c.fonts.web.size.default = 18 # webpage
c.fonts.web.size.default_fixed = 18
c.fonts.web.size.minimum = 18
c.fonts.hints = 'normal 12pt default_family'
c.fonts.tabs.selected = '12pt default_family'
c.fonts.tabs.unselected = '12pt default_family'
c.fonts.statusbar = '14.5pt default_family'

c.tabs.show = "always"
c.tabs.position = "top"
c.tabs.padding = {"bottom":0, "left":0, "right":0, "top":0}
c.tabs.indicator.width = 0
c.tabs.width = '7%'
c.tabs.title.format = '{audio}{current_title}'
c.tabs.title.format_pinned = '[P]{audio}{current_title}'
c.statusbar.show = "always"
c.completion.height = '30%'

c.keyhint.delay = 0
c.hints.uppercase = False
c.hints.chars = "asdfjkl;"
c.hints.min_chars = 2
c.hints.auto_follow = "full-match"

c.downloads.location.directory = "~/Downloads"
c.downloads.location.prompt = False
c.downloads.location.suggestion = 'both'
c.downloads.location.remember = False
c.downloads.remove_finished = 3300
c.downloads.position = "bottom"

c.content.fullscreen.window = True # Limit fullscreen to browser window
c.content.autoplay = False
c.content.blocking.enabled = True
c.content.blocking.method = 'both'
c.content.blocking.adblock.lists = [
  "https://easylist.to/easylist/easylist.txt",
  "https://secure.fanboy.co.nz/fanboy-cookiemonster.txt",
  "https://easylist.to/easylist/easyprivacy.txt",
  "https://secure.fanboy.co.nz/fanboy-annoyance.txt",]

# Sites pick their content language from this header (navigator.language
# follows it too), so ask for Chinese first and keep English as fallback.
c.content.headers.accept_language = 'zh-CN,zh;q=0.9,en;q=0.8'

# privacy
c.content.geolocation = False
c.content.webrtc_ip_handling_policy = "default-public-interface-only"
c.completion.open_categories = ['filesystem']

# Browser-UI colors generated from the current wallpaper by matugen (template:
# ~/.config/matugen/templates/qutebrowser-colors.py, refreshed on every
# wallpaper change via ~/.config/scripts/matugen-update.sh).
# Sourced last on purpose, so it overrides the hand-written UI colors in
# colors.py. Skipped when it does not exist yet: sourcing a missing file makes
# qutebrowser report a config error.
matugen_colors = os.path.join(os.path.dirname(__file__), 'matugen_colors.py')
if os.path.exists(matugen_colors):
    config.source(matugen_colors)
