# Unset the default fish greeting text which messes up Zellij
set fish_greeting

# Uses nvim as default editor
set -x EDITOR nvim
set -x VISUAL nvim

# Add local bin to PATH
fish_add_path $HOME/.local/bin

if status is-interactive
    export ZELLIJ_CONFIG_DIR=$HOME/.config/zellij

    if [ "$TERM" = "xterm-ghostty" ]
        eval (zellij setup --generate-auto-start fish | string collect)
    end
end

zoxide init fish --cmd j | source
pyenv init - | source
nodenv init - | source
direnv hook fish | source
starship init fish | source
