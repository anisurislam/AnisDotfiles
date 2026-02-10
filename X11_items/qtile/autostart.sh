#!/bin/sh

xrandr --output HDMI-1 --mode 1920x1080 --rate 100 &
command -v dunst && dunst &
command -v picom && picom --config ~/.config/picom/picom.conf &
command -v qbittorrent && qbittorrent &
command -v easyeffects && easyeffects &
command -v greenclip && greenclip daemon &
