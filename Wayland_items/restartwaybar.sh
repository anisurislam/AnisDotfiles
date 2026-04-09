#!/bin/bash

pkill -x waybar
sleep 0.2

setsid waybar -c ~/.config/mango/config.jsonc -s ~/.config/mango/style.css >/dev/null 2>&1 &