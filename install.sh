#!/bin/bash

set -euo pipefail

echo "####################################"
echo "STARTING INSTALLATION SCRIPT"
echo "####################################"

# Variables
session_type=""
window_manager=""

info()  { printf "[INFO] %s\n" "$*"; }
warn()  { printf "[WARN] %s\n" "$*"; }
error() { printf "[ERROR] %s\n" "$*"; exit 1; }

# Selecting session type
while true; do
    echo "Choose session type:"
    echo "1) X11"
    echo "2) Wayland"
    read -rp "Enter choice [1-2]: " choice
    
    case "$choice" in
        1|x11)
            session_type="x11"
            break
        ;;
        2|wayland)
            session_type="wayland"
            break
        ;;
        *)
            echo "Invalid choice. Please enter 1 or 2."
        ;;
    esac
done

echo "Selected session type: $session_type"

# Selecting a window manager
if [[ "$session_type" == "x11" ]]; then
    while true; do
        echo
        echo "Select a X11 Window Manager:"
        echo "1) awesomewm"
        echo "2) qtile"
        echo "3) bspwm"
        read -rp "Enter choice [1-3 or name]: " wm_choice_input
        
        case "${wm_choice_input,,}" in
            1|awesome|awesomewm)
                window_manager="awesomewm"
                break
            ;;
            2|qtile)
                window_manager="qtile"
                break
            ;;
            3|bspwm)
                window_manager="bspwm"
                break
            ;;
            *)
                echo "Invalid choice. Please enter 1, 2, 3, or the WM name."
            ;;
        esac
    done
else
    while true; do
        echo
        echo "Select a Wayland Window Manager:"
        echo "1) hyprland"
        echo "2) mangowm"
        read -rp "Enter choice [1-2 or name]: " wm_choice_input
        
        case "${wm_choice_input,,}" in
            1|hypr|hyprland)
                window_manager="hyprland"
                break
            ;;
            2|mango|mangowm)
                window_manager="mangowm"
                break
            ;;
            *)
                echo "Invalid choice. Please enter 1, 2, or the WM name."
            ;;
        esac
    done
fi

export SESSION_TYPE="$session_type"
export WINDOW_MANAGER="$window_manager"
echo
info "Final selection:"
echo "  Session type: $SESSION_TYPE"
echo "  Window manager: $WINDOW_MANAGER"
echo


# Ensuring pacman is available
if ! command -v pacman >/dev/null 2>&1; then
    error "pacman not found. This script is for Arch Linux."
fi

# Installing paru (AUR Helper)
install_paru() {
    if command -v paru >/dev/null 2>&1; then
        info "paru is already installed."
        return
    fi
    info "Installing paru (AUR helper)..."
    sudo pacman -S --needed --noconfirm base-devel git
    tmp_dir=$(mktemp -d)
    info "Cloning paru into $tmp_dir"
    git clone https://aur.archlinux.org/paru.git "$tmp_dir/paru" || error "Failed to clone paru."
    (
        cd "$tmp_dir/paru"
        makepkg -si --noconfirm
    )
    rm -rf "$tmp_dir"
    info "paru installed successfully."
}
install_paru
command -v paru >/dev/null 2>&1 || error "paru is required but not installed"


# Defining package lists
COMMON_PKGS=(kitty git neovim rofi ranger firefox mpv flameshot htop rsync)
X11_PKGS=(xorg-xinit xorg-server)
WAYLAND_PKGS=(wayland-protocols wl-clipboard mako swaybg waybar)

# Installing packages based on the selected window manager
case "$WINDOW_MANAGER" in
    qtile)
        WM_PKGS=(qtile python-pip python-xcffib python-cairocffi rofi-greenclip)
        WM_AUR_PKGS=()
        DOTFILES_SRC="./X11_items/qtile"
        CONFIG_NAME="qtile"
    ;;
    awesomewm)
        WM_PKGS=(awesome lua)
        WM_AUR_PKGS=()
        DOTFILES_SRC="./X11_items/awesome"
        CONFIG_NAME="awesome"
    ;;
    bspwm)
        WM_PKGS=(bspwm sxhkd polybar)
        WM_AUR_PKGS=()
        DOTFILES_SRC="./X11_items/bspwm"
        CONFIG_NAME="bspwm"
    ;;
    hyprland)
        WM_PKGS=(hyprland)
        WM_AUR_PKGS=()
        DOTFILES_SRC="./Wayland_items/hypr"
        CONFIG_NAME="hypr"
    ;;
    mangowm)
        WM_PKGS=(cliphist)
        WM_AUR_PKGS=(mangowm)
        DOTFILES_SRC="./Wayland_items/mango"
        CONFIG_NAME="mango"
    ;;
    *)
        warn "Unknown window manager: $WINDOW_MANAGER"
        WM_PKGS=()
        WM_AUR_PKGS=()
        DOTFILES_SRC=""
        CONFIG_NAME=""
    ;;
esac

# Initializing install dotfiles function
install_dotfiles() {
    local SRC="$DOTFILES_SRC"
    local NAME="$CONFIG_NAME"
    
    if [[ -z "$SRC" || -z "$NAME" ]]; then
        warn "Skipping dotfiles (missing SRC or CONFIG_NAME)"
        return
    fi
    
    local DEST="$HOME/.config/$NAME"
    
    if [[ ! -d "$SRC" ]]; then
        warn "Dotfiles source not found, skipping: $SRC"
        return
    fi
    
    info "Installing dotfiles:"
    info "  From: $SRC"
    info "  To:   $DEST"
    
    mkdir -p "$DEST"
    
    rsync -av --delete "$SRC/" "$DEST/"
    
    info "Dotfiles installed successfully."
}


# Combining package groups
if [[ "$SESSION_TYPE" == "x11" ]]; then
    PKGS=("${COMMON_PKGS[@]}" "${X11_PKGS[@]}" "${WM_PKGS[@]}")
else
    PKGS=("${COMMON_PKGS[@]}" "${WAYLAND_PKGS[@]}" "${WM_PKGS[@]}")
fi
# Removing duplicates
mapfile -t PKGS < <(printf "%s\n" "${PKGS[@]}" | sort -u)

# Showing the list of packages and asking for confirmation
if [[ ${#PKGS[@]} -gt 0 ]]; then
    echo
    info "The following packages will be installed via pacman:"
    printf '  %s\n' "${PKGS[@]}"
    echo
    read -rp "Proceed with pacman -Syu --needed for these packages? [y/N]: " confirm_pkgs
    case "${confirm_pkgs,,}" in
        y|yes)
            echo
            info "Running: sudo pacman -Syu --needed ${PKGS[*]}"
            sudo pacman -Syu --needed "${PKGS[@]}"
            
            if [[ ${#WM_AUR_PKGS[@]} -gt 0 ]]; then
                echo
                info "Installing AUR packages via paru:"
                printf '  %s\n' "${WM_AUR_PKGS[@]}"
                paru -S --needed "${WM_AUR_PKGS[@]}"
            fi
            install_dotfiles
        ;;
        *)
            info "Package installation skipped by user."
        ;;
    esac
else
    info "No packages to install for the selected window manager."
fi

