PATH=/opt/homebrew/bin:/opt/homebrew/sbin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH

eval "$(/opt/homebrew/bin/brew shellenv)"

eval "$(zoxide init zsh --cmd j)"
eval "$(pyenv init -)"
eval "$(nodenv init -)"
eval "$(direnv hook zsh)"
eval "$(starship init zsh)"
eval "$(rbenv init -)"

# pnpm
export PNPM_HOME="/Users/Feynman/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# edit-and-execute-command
# raycast://extensions/raycast/raycast-ai/ai-chat?context=%7B%22id%22:%2218F860A7-0A96-4B58-9C94-65D4470CF830%22%7D
autoload -U edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

alias g=git


