PATH=/opt/homebrew/bin:/opt/homebrew/sbin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH

eval "$(/opt/homebrew/bin/brew shellenv)"

# Completion system -- must load after brew shellenv extends $fpath
autoload -Uz compinit
compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

eval "$(zoxide init zsh --cmd j)"
eval "$(pyenv init -)"
eval "$(goenv init -)"
eval "$(nodenv init -)"
eval "$(direnv hook zsh)"
eval "$(starship init zsh)"
eval "$(rbenv init -)"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

export PATH="$HOME/.local/bin:$PATH"

# Key bindings
#
# bindkey -e is not redundant. When $EDITOR or $VISUAL contains the string "vi",
# zsh picks vi keybindings on its own -- and "nvim" contains "vi", so setting
# EDITOR below silently opts this shell into viins. In viins ^R is `redisplay`,
# not history search, so reverse search appears to do nothing at all.
#
# This must also stay above the bindings that follow: they target the main
# keymap, and switching keymaps afterwards would strand them in viins.
bindkey -e

# edit-and-execute-command
# raycast://extensions/raycast/raycast-ai/ai-chat?context=%7B%22id%22:%2218F860A7-0A96-4B58-9C94-65D4470CF830%22%7D
autoload -U edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

alias g=git

export EDITOR=nvim
export VISUAL=nvim
