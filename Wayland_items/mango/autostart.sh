# waybar
waybar -c ~/.config/mango/config.jsonc -s ~/.config/mango/style.css >/dev/null 2>&1 &

# wallpaper
swaybg -i ~/Pictures/wallpapers/wallpaper2.jpg >/dev/null 2>&1 &

# clipboard manager
wl-paste --type text --watch cliphist store >/dev/null 2>&1 &
wl-paste --type image --watch cliphist store >/dev/null 2>&1 &