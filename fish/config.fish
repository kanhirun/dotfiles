# Unset the default fish greeting text which messes up Zellij
set fish_greeting

if status is-interactive
    export ZELLIJ_CONFIG_DIR=$HOME/.config/zellij

    if [ "$TERM" = "xterm-ghostty" ]
        eval (zellij setup --generate-auto-start fish | string collect)
    end
end

eval "$(zoxide init fish --cmd j)"

starship init fish | source
