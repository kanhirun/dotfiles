#
# Executes commands at the start of an interactive session.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Use nvim instead of nano
export VISUAL=nvim
export EDITOR=nvim
export DEFAULT_USER=$USER                          # Turns on a feature for the ZSH theme, `agnoster`.

# Avoid duplicate history
export HISTCONTROL=ignoreboth:erasedups
setopt hist_ignore_all_dups

# Use fzf (if it exists) for fuzzy searching
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

if which fasd >/dev/null; then 
  eval "$(fasd --init auto)"
  alias j='fasd_cd -d'
fi

if which rbenv >/dev/null;     then eval "$(rbenv init -)"; fi
if which pyenv >/dev/null;     then eval "$(pyenv init -)"; fi
if which nodenv >/dev/null;    then eval "$(nodenv init -)"; fi
if which jenv >/dev/null;      then eval "$(jenv init -)"; fi
if which asciinema >/dev/null; then alias asci=asciinema; fi
if which direnv >/dev/null; then eval "$(direnv hook zsh)"; fi

# Use <C-x-e> to edit the current command
# - To edit the previous command, use `fc`
autoload -U     edit-command-line
zle      -N     edit-command-line

# Use emacs mode for zsh line editor (zle)
# do `bindkey` to show list of commands
bindkey -e

# ITerm2 Shell Integration
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# Use standard reverse instead of fzf
bindkey "^R" history-incremental-search-backward

# Allows overwrites when using UNIX redirect
#   For example, `cat some_text > existing_file` (without emitting file permission errors)
setopt clobber

# Prints the name of the connected network
function whereami() {
  /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I | sed -e "s/^  *SSID: //p" -e d
}
