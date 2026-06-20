#!/usr/bin/env bash

## Copyright (C) 2020-2026 Aditya Shakya <adi1090x@gmail.com>
##
## Set GTK Themes, Icons, Cursor and Fonts

THEME='MacTahoe-Dark-nord'
ICONS='MacTahoe-grey-dark'
FONT='JetBrainsMono Nerd Font Light 11'
CURSOR='Qogirr-cursors'

SCHEMA='gsettings set org.gnome.desktop.interface'

apply_themes () {
	${SCHEMA} gtk-theme "$THEME"
	${SCHEMA} icon-theme "$ICONS"
	${SCHEMA} cursor-theme "$CURSOR"
	${SCHEMA} font-name "$FONT"
}

apply_themes
