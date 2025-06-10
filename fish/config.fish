# ========================
# Environment Variables
# ========================

# Unset the default fish greeting text which messes up Zellij
set fish_greeting

# Uses nvim as default editor
set -x EDITOR nvim
set -x VISUAL nvim

set -x PNPM_HOME $HOME/Library/pnpm

# ========================
# Extending PATH
# ========================

fish_add_path $HOME/.local/bin

if not string match -q "*$PNPM_HOME*" "$PATH"
    fish_add_path $PNPM_HOME
end

if status is-interactive
    export ZELLIJ_CONFIG_DIR=$HOME/.config/zellij

    if [ "$TERM" = "xterm-ghostty" ]
        eval (zellij setup --generate-auto-start fish | string collect)
    end
end

# ========================
# Plugin Initialization
# ========================

zoxide init fish --cmd j | source
pyenv init - | source
nodenv init - | source
direnv hook fish | source
starship init fish | source
