#!/bin/bash

set -euo pipefail

# Setting up logging
LOGFILE="$HOME/install-$(date +%s).log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "####################################"
echo "STARTING INSTALLATION SCRIPT"
echo "####################################"

# Variables
session_type=""
window_manager=""
info() { printf "[INFO] %s\n" "$*"; }
warn() { printf "[WARN] %s\n" "$*"; }
error() {
    printf "[ERROR] %s\n" "$*"
    exit 1
}

info "Logging to $LOGFILE"

# Selecting session type
while true; do
    echo "Choose session type:"
    echo "1) X11"
    echo "2) Wayland"
    read -rp "Enter choice [1-2]: " choice

    case "$choice" in
    1 | x11)
        session_type="x11"
        break
        ;;
    2 | wayland)
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
        echo "Select an X11 Window Manager:"
        echo "1) awesomewm"
        echo "2) qtile"
        echo "3) bspwm"
        read -rp "Enter choice [1-3 or name]: " wm_choice_input

        case "${wm_choice_input,,}" in
        1 | awesome | awesomewm)
            window_manager="awesomewm"
            break
            ;;
        2 | qtile)
            window_manager="qtile"
            break
            ;;
        3 | bspwm)
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
        1 | hypr | hyprland)
            window_manager="hyprland"
            break
            ;;
        2 | mango | mangowm)
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
COMMON_PKGS=(kitty git neovim rofi yazi firefox mpv viewnior flameshot htop rsync sddm networkmanager pavucontrol ttf-jetbrains-mono-nerd zoxide)
X11_PKGS=(xorg-xinit xorg-server lxappearance)
WAYLAND_PKGS=(wayland-protocols wl-clipboard mako swaybg waybar nwg-look)

# Installing packages based on the selected window manager
case "$WINDOW_MANAGER" in
qtile)
    WM_PKGS=(qtile python-pip python-xcffib python-cairocffi)
    WM_AUR_PKGS=(rofi-greenclip)
    DOTFILES_LIST=(
        "qtile:./X11_items/qtile"
    )
    ;;
awesomewm)
    WM_PKGS=(awesome lua)
    WM_AUR_PKGS=()
    DOTFILES_LIST=(
        "awesome:./X11_items/awesome"
    )
    ;;
bspwm)
    WM_PKGS=(bspwm sxhkd polybar)
    WM_AUR_PKGS=()
    DOTFILES_LIST=(
        "bspwm:./X11_items/bspwm"
        "polybar:./X11_items/polybar"
    )
    ;;
hyprland)
    WM_PKGS=(hyprland)
    WM_AUR_PKGS=()
    DOTFILES_LIST=(
        "hypr:./Wayland_items/hypr"
        "waybar:./Wayland_items/waybar"
    )
    ;;
mangowm)
    WM_PKGS=(cliphist)
    WM_AUR_PKGS=(mangowm)
    DOTFILES_LIST=(
        "mango:./Wayland_items/mango"
    )
    ;;
*)
    warn "Unknown window manager: $WINDOW_MANAGER"
    WM_PKGS=()
    WM_AUR_PKGS=()
    DOTFILES_LIST=()
    ;;
esac

# Combining package groups
if [[ "$SESSION_TYPE" == "x11" ]]; then
    PKGS=("${COMMON_PKGS[@]}" "${X11_PKGS[@]}" "${WM_PKGS[@]}")
else
    PKGS=("${COMMON_PKGS[@]}" "${WAYLAND_PKGS[@]}" "${WM_PKGS[@]}")
fi
# Removing duplicates
mapfile -t PKGS < <(printf "%s\n" "${PKGS[@]}" | sort -u)

# Showing the list of packages and asking for confirmation
# Initializing install packages function
install_packages() {
    if [[ ${#PKGS[@]} -gt 0 ]]; then
        echo
        info "The following packages will be installed via pacman:"
        printf '  %s\n' "${PKGS[@]}"
        echo
        read -rp "Proceed with pacman -Syu --needed for these packages? [y/N]: " confirm_pkgs
        case "${confirm_pkgs,,}" in
        y | yes)
            echo
            info "Running: sudo pacman -Syu --needed ${PKGS[*]}"
            sudo pacman -Syu --needed "${PKGS[@]}"

            if [[ ${#WM_AUR_PKGS[@]} -gt 0 ]]; then
                echo
                info "Installing AUR packages via paru:"
                printf '  %s\n' "${WM_AUR_PKGS[@]}"
                paru -S --needed --noconfirm "${WM_AUR_PKGS[@]}"
            fi
            ;;
        *)
            info "Package installation skipped by user."
            ;;
        esac
    else
        info "No packages to install for the selected window manager."
    fi

}

# Initializing install dotfiles function
install_dotfiles() {
    if [[ ${#DOTFILES_LIST[@]} -eq 0 ]]; then
        info "No dotfiles to install."
        return
    fi

    for entry in "${DOTFILES_LIST[@]}"; do
        local NAME="${entry%%:*}"
        local SRC="${entry##*:}"
        local DEST="$HOME/.config/$NAME"

        if [[ ! -d "$SRC" ]]; then
            warn "Dotfiles source not found, skipping: $SRC"
            continue
        fi

        info "Installing dotfiles:"
        info "  From: $SRC"
        info "  To:   $DEST"

        mkdir -p "$DEST"
        rsync -av --delete "$SRC/" "$DEST/"

        info "Dotfiles for '$NAME' installed successfully."
    done
}

# Initializing install zsh function
install_zsh() {
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        info "Oh My Zsh is already installed."
        return
    fi
    info "Installing Zsh..."
    sudo pacman -S --needed --noconfirm zsh git curl

    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        info "Installing Oh My Zsh..."
        RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    else
        info "Oh My Zsh already installed, skipping..."
    fi

    # Plugins
    ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    clone_if_missing() {
        local repo="$1"
        local dest="$2"

        if [[ -d "$dest" ]]; then
            info "Plugin already exists, skipping: $dest"
        else
            git clone "$repo" "$dest"
        fi
    }

    clone_if_missing "https://github.com/zsh-users/zsh-autosuggestions.git" "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    clone_if_missing "https://github.com/zsh-users/zsh-syntax-highlighting.git" "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    clone_if_missing "https://github.com/zdharma-continuum/fast-syntax-highlighting.git" "$ZSH_CUSTOM/plugins/fast-syntax-highlighting"
    clone_if_missing "https://github.com/marlonrichert/zsh-autocomplete.git" "$ZSH_CUSTOM/plugins/zsh-autocomplete"

    if grep -q "^plugins=" "$HOME/.zshrc"; then
        sed -i 's/^plugins=.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "$HOME/.zshrc"
    else
        echo "plugins=(git zsh-autosuggestions zsh-syntax-highlighting)" >>"$HOME/.zshrc"
    fi

    # Adding custom Zsh configuration
    cat <<-'EOF' >>"$HOME/.zshrc"
	    # Custom Zsh configuration
	    eval "$(zoxide init zsh)"
	    export EDITOR="nvim"
	    alias vim="nvim"
	    alias cd="z"

	EOF

    # Setting Zsh as default shell
    if [[ "$SHELL" != "$(command -v zsh)" ]]; then
        info "Setting Zsh as default shell..."
        chsh -s "$(command -v zsh)" || warn "Failed to change default shell"
    fi
}

# Running the installation functions to intsall packages and dotfiles
install_packages
install_dotfiles
install_zsh

final_tweaks() {
    echo
    info "Running final tweaks..."
    sudo systemctl enable sddm
    sudo systemctl enable NetworkManager
    info "Final tweaks completed."
}
final_tweaks

echo "####################################"
echo "INSTALLATION COMPLETE!"
echo "Reboot your system to start using your new setup."
echo "####################################"
