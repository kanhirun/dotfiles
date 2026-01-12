export AVANTE_ANTHROPIC_API_KEY=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

eval "$(zoxide init zsh --cmd j)"
eval "$(pyenv init -)"
eval "$(nodenv init -)"
eval "$(direnv hook zsh)"
eval "$(starship init zsh)"

# pnpm
export PNPM_HOME="/Users/Feynman/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
