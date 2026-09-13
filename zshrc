PATH=/opt/homebrew/bin:/opt/homebrew/sbin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH

eval "$(/opt/homebrew/bin/brew shellenv)"

# Session transcript
#
# Record this shell's input and output to <dirname>.log in the directory it
# started in, so an agent can read what was typed and what came back.
#
# The recursion guard is not optional. `script` starts a NEW shell, which sources
# this file again, which starts another `script` -- forever. SHELL_TRANSCRIPT
# marks the inner shell so it falls straight through. It sits this early so the
# outer shell skips compinit and the version-manager evals it would only redo.
#
# Skipped under Claude Code and inside Neovim's terminal: both already surface
# their own output, and recording a full-screen TUI writes megabytes of escape
# sequences to a file nobody can read. NO_TRANSCRIPT=1 opts out of one shell.
#
# `command -v` first so a missing `script` falls through to a normal shell rather
# than exiting immediately and leaving an unusable terminal.
if [[ -o interactive && -z $SHELL_TRANSCRIPT && -z $NO_TRANSCRIPT && -z $CLAUDECODE && -z $NVIM ]]; then
  if command -v script >/dev/null; then
    export SHELL_TRANSCRIPT="${PWD:t}.log"
    script -q "$SHELL_TRANSCRIPT"
    exit
  fi
fi

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
