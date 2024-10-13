#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
fi

# export GTK_IM_MODULE=fcitx5
# export QT_IM_MODULE=fcitx5
# export XMODIFIERS=@im=fcitx5

# alias
alias ll='ls -al'
# alias microsoft-edge-stable='microsoft-edge-stable --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-wayland-ime'
# alias code='code --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-wayland-ime'
