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
    # Outside the repo, deliberately. A transcript in a project root is one
    # `git add -f`, one missing global gitignore, or one clone on another machine
    # away from being committed -- permanently, possibly publicly. Named by
    # project so it stays findable without living next to the code.
    SHELL_TRANSCRIPT_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/shell-logs"
    mkdir -p "$SHELL_TRANSCRIPT_DIR" && chmod 700 "$SHELL_TRANSCRIPT_DIR"

    # Retention. A secret that reaches a transcript should age out rather than
    # sit on disk forever; deleting later does not undo exposure, but it does
    # bound how much history one mistake covers.
    find "$SHELL_TRANSCRIPT_DIR" -name '*.log' -mtime +7 -delete 2>/dev/null

    export SHELL_TRANSCRIPT="$SHELL_TRANSCRIPT_DIR/${PWD:t}-$(date +%Y%m%d-%H%M%S).log"

    # Created and locked down BEFORE script opens it, then appended to with -a.
    # Setting `umask 077` around the call instead would work, but script passes
    # its umask to the shell it starts -- every file written during the session
    # would come out 0600 too.
    : > "$SHELL_TRANSCRIPT" && chmod 600 "$SHELL_TRANSCRIPT"
    script -q -a "$SHELL_TRANSCRIPT"
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
