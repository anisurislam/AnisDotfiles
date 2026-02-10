import os

import libqtile.resources
import subprocess
import datetime
import psutil
from libqtile import bar, layout, qtile, widget, hook
from libqtile.config import Click, Drag, Group, Key, Match, Screen
from libqtile.lazy import lazy
from libqtile.utils import guess_terminal
from libqtile.widget import base

mod = "mod4"
terminal = guess_terminal()

######### colors ############
colors = {
    "bg": "#1E1E2E",
    "fg": "#C0CAF5",
    "border_focus": "#00bfff",
    "group_active": "#F9E2AF",
    "group_inactive": "#4C566A",
    "group_fill": "#636e72",
    "separator": "#44444E",
    "clock": "#88c0d0",
}

########### keybinds ##################
keys = [
    # window management
    Key([mod], "h", lazy.layout.left(), desc="Move focus to left"),
    Key([mod], "l", lazy.layout.right(), desc="Move focus to right"),
    Key([mod], "j", lazy.layout.down(), desc="Move focus down"),
    Key([mod], "k", lazy.layout.up(), desc="Move focus up"),
    Key(
        [mod, "shift"], "h", lazy.layout.shuffle_left(), desc="Move window to the left"
    ),
    Key(
        [mod, "shift"],
        "l",
        lazy.layout.shuffle_right(),
        desc="Move window to the right",
    ),
    Key([mod, "shift"], "j", lazy.layout.shuffle_down(), desc="Move window down"),
    Key([mod, "shift"], "k", lazy.layout.shuffle_up(), desc="Move window up"),
    # Grow windows. If current window is on the edge of screen and direction
    # will be to screen edge - window would shrink.
    Key([mod, "control"], "h", lazy.layout.grow_left(), desc="Grow window to the left"),
    Key(
        [mod, "control"], "l", lazy.layout.grow_right(), desc="Grow window to the right"
    ),
    Key([mod, "control"], "j", lazy.layout.grow_down(), desc="Grow window down"),
    Key([mod, "control"], "k", lazy.layout.grow_up(), desc="Grow window up"),
    Key([mod], "n", lazy.layout.normalize(), desc="Reset all window sizes"),
    # Toggle between split and unsplit sides of stack.
    # Split = all windows displayed
    # Unsplit = 1 window displayed, like Max layout, but still with
    # multiple stack panes
    Key(
        [mod, "shift"],
        "Return",
        lazy.layout.toggle_split(),
        lazy.spawn("notify-send 'SPLIT/UNSPLIT Toggled'"),
        desc="Toggle between split and unsplit sides of stack",
    ),
    Key([mod], "Return", lazy.spawn(terminal), desc="Launch terminal"),
    # Toggle between different layouts as defined below
    Key([mod], "Tab", lazy.next_layout(), desc="Toggle between layouts"),
    Key([mod], "q", lazy.window.kill(), desc="Kill focused window"),
    Key(
        [mod],
        "f",
        lazy.window.toggle_fullscreen(),
        desc="Toggle fullscreen on the focused window",
    ),
    Key(
        [mod],
        "space",
        lazy.window.toggle_floating(),
        desc="Toggle floating on the focused window",
    ),
    Key([mod, "control"], "r", lazy.restart(), desc="Reload the config"),
    Key([mod], "d", lazy.spawn("rofi -show drun"), desc="Launch Rofi (App launcher)"),
    Key(
        [mod],
        "v",
        lazy.spawn(
            "rofi -modi 'clipboard:greenclip print' -show clipboard -run-command '{cmd}'"
        ),
        desc="Launch Clipboard Manager with rofi (greenclip)",
    ),
    Key(
        [mod],
        "b",
        lazy.spawn(
            "brave --enable-features=AcceleratedVideoDecodeLinuxZeroCopyGL,AcceleratedVideoDecodeLinuxGL,AcceleratedVideoEncoder"
        ),
        desc="Launch brave browser",
    ),
    Key([mod], "c", lazy.spawn("chromium"), desc="Launch chromium  browser"),
    Key([mod], "e", lazy.spawn("thunar"), desc="Launch Thunar File Manager"),
    Key([], "Print", lazy.spawn("flameshot gui"), desc="Take Screenshot"),
]


groups = [Group(i) for i in "123456789"]

for i in groups:
    keys.extend(
        [
            # mod + group number = switch to group
            Key(
                [mod],
                i.name,
                lazy.group[i.name].toscreen(),
                desc=f"Switch to group {i.name}",
            ),
            # mod + shift + group number = switch to & move focused window to group
            Key(
                [mod, "shift"],
                i.name,
                lazy.window.togroup(i.name, switch_group=True),
                desc=f"Switch to & move focused window to group {i.name}",
            ),
        ]
    )


############## layouts ###################
layouts = [
    layout.Columns(
        margin=[5, 1, 5, 1],
        border_width=3,
        border_focus=colors["border_focus"],
    ),
    # layout.Max(),
    # layout.Stack(num_stacks=2),
    # layout.Bsp(),
    # layout.Matrix(),
    # layout.MonadTall(),
    # layout.MonadWide(),
    # layout.RatioTile(),
    layout.Tile(
        margin=[5, 1, 5, 1],
        border_width=3,
        border_focus=colors["border_focus"],
    ),
    # layout.TreeTab(),
    # layout.VerticalTile(),
    # layout.Zoomy(),
]


#################### widgets #######################
widget_defaults = dict(
    background=colors["bg"],
    font="JetBrainsMono Nerd Font",
    fontsize=13,
    foreground=colors["fg"],
    padding=0,
)
extension_defaults = widget_defaults.copy()


def toggle_clock_format():
    for widget in qtile.widgets_map.values():
        if widget.name == "clock" and widget.format == "%I:%M %p":
            widget.format = "%A-%d-%b-%Y %I:%M %p"
        elif widget.name == "clock" and widget.format == "%A-%d-%b-%Y %I:%M %p":
            widget.format = "%I:%M %p"


def disk_used(path="/"):
    return subprocess.check_output(
        ["bash", "-c", f"df -h --output=used {path} | tail -n 1"], text=True
    ).strip()


logo = os.path.join(os.path.dirname(libqtile.resources.__file__), "logo.png")
screens = [
    Screen(
        top=bar.Bar(
            [
                # Left
                widget.GroupBox(
                    active=colors["group_active"],
                    inactive=colors["group_inactive"],
                    rounded=True,
                    highlight_method="block",
                    this_current_screen_border=colors["group_fill"],
                    padding=6,
                    disable_drag=True,
                ),
                widget.WindowName(
                    max_chars=40,
                    format="{name}",
                ),
                widget.Spacer(length=bar.STRETCH),
                # Center
                widget.Clock(
                    foreground=colors["clock"],
                    fontsize=15,
                    format="%I:%M %p",
                    name="clock",
                    mouse_callbacks={"Button1": toggle_clock_format},
                ),
                widget.Spacer(length=bar.STRETCH),
                # Right
                widget.Net(
                    interface="enp2s0",
                    update_interval=1,
                    format="{down:.2f}{down_suffix}  {up:.2f}{up_suffix}",
                ),
                widget.Sep(size_percent=50, padding=20, foreground=colors["separator"]),
                widget.GenPollText(
                    func=lambda: disk_used("/"),
                ),
                widget.Sep(size_percent=50, padding=20, foreground=colors["separator"]),
                widget.GenPollText(
                    func=lambda: disk_used("/home"),
                ),
                widget.Sep(size_percent=50, padding=20, foreground=colors["separator"]),
                widget.PulseVolume(
                    fmt="󰕾 {}",
                    mouse_callbacks={
                        "Button1": lambda: qtile.cmd_spawn("pavucontrol"),
                        "Button4": lambda: qtile.cmd_spawn(
                            "pactl set-sink-volume @DEFAULT_SINK@ +5%"
                        ),
                        "Button5": lambda: qtile.cmd_spawn(
                            "pactl set-sink-volume @DEFAULT_SINK@ -5%"
                        ),
                        "Button3": lambda: qtile.cmd_spawn(
                            "pactl set-sink-mute @DEFAULT_SINK@ toggle"
                        ),
                    },
                ),
                widget.Sep(size_percent=50, padding=20, foreground=colors["separator"]),
                widget.Memory(
                    update_interval=2,
                    format=" {MemUsed: .0f}{mm}",
                ),
                widget.Sep(size_percent=50, padding=20, foreground=colors["separator"]),
                widget.CPU(
                    format=" {load_percent}%",
                    update_interval=2.0,
                ),
                widget.Sep(size_percent=50, padding=20, foreground=colors["separator"]),
                widget.CurrentLayout(),
                widget.Sep(size_percent=50, padding=20, foreground=colors["separator"]),
                widget.Systray(
                    icon_size=15,
                    padding=5,
                ),
            ],
            24,
            margin=[2, 5, 0, 5],
            border_width=[3, 10, 5, 3],
            border_color=colors["bg"],
        ),
        right=bar.Gap(5),
        left=bar.Gap(5),
        wallpaper="~/Pictures/wallpapers/wallpaper2.jpg",
        wallpaper_mode="center",
    ),
]

# Drag floating layouts.
mouse = [
    Drag(
        [mod],
        "Button1",
        lazy.window.set_position_floating(),
        start=lazy.window.get_position(),
    ),
    Drag(
        [mod],
        "Button3",
        lazy.window.set_size_floating(),
        start=lazy.window.get_size(),
    ),
    Click([mod], "Button2", lazy.window.bring_to_front()),
]

dgroups_key_binder = None
dgroups_app_rules = []
follow_mouse_focus = True
bring_front_click = False
floats_kept_above = True
cursor_warp = False
floating_layout = layout.Floating(
    float_rules=[
        # Run the utility of `xprop` to see the wm class and name of an X client.
        *layout.Floating.default_float_rules,
        Match(wm_class="confirmreset"),  # gitk
        Match(wm_class="makebranch"),  # gitk
        Match(wm_class="maketag"),  # gitk
        Match(wm_class="ssh-askpass"),  # ssh-askpass
        Match(title="branchdialog"),  # gitk
        Match(title="pinentry"),  # GPG key password entry
        Match(wm_class="gpicview"),  # Image viewer
    ]
)
auto_fullscreen = True
focus_on_window_activation = "smart"
focus_previous_on_window_remove = False
reconfigure_screens = True

# If things like steam games want to auto-minimize themselves when losing
# focus, should we respect this or not?
auto_minimize = True

# When using the Wayland backend, this can be used to configure input devices.
wl_input_rules = None

# xcursor theme (string or None) and size (integer) for Wayland backend
wl_xcursor_theme = None
wl_xcursor_size = 24


# Moving applications to specific workspace / group
@hook.subscribe.client_new
def assign_app_group(window):
    wm_class = window.window.get_wm_class()
    if wm_class:
        cls = wm_class[1].lower()
        if cls == "brave-browser" or cls == "chromium":
            window.togroup("2", switch_group=False)

            # This part might not be needed after installing fresh archlinux (not sure). Change above to True and remove this.
            def switch():
                try:
                    qtile.groups_map["2"].cmd_toscreen()
                except Exception as e:
                    print(f"Failed to switch to group 2: {e}")

            qtile.call_later(0.1, switch)
        elif cls == "qbittorrent":
            window.togroup("5", switch_group=False)


wmname = "LG3D"


########## autostart applications #################
@hook.subscribe.startup_once
def autostart():
    home = os.path.expanduser("~/.config/qtile/autostart.sh")
    subprocess.call(home)
