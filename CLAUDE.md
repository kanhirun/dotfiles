# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository containing configuration files for various development tools on macOS.

## Common Commands

### Installation
```bash
brew bundle  # Install all Homebrew packages from Brewfile
```

**Note**: This repository contains configuration files only. You'll need to manually symlink these configs to their expected locations (e.g., `ln -s ~/dotfiles/nvim ~/.config/nvim`).

### Shell Configuration

The repository supports both Fish and Zsh shells:

- **Fish**: Primary config in `fish/config.fish`, integrates with Zellij terminal multiplexer when using Ghostty terminal. Empty `functions/` and `completions/` directories.
- **Zsh**: Config in `zsh/zshrc`, uses Prezto framework and supports various development tools. Includes Warp terminal (replacing iTerm2).

### Development Environment Management

```bash
# Ruby version management
rbenv install <version>
rbenv local <version>

# Python version management  
pyenv install <version>
pyenv local <version>

# Directory-specific environment variables
direnv allow  # After creating/modifying .envrc
```

## Architecture & Key Integrations

### Neovim Configuration (`nvim/init.lua`)
- **Plugin Manager**: lazy.nvim
- **LSP Support**: Mason + nvim-lspconfig for Python (pyright), TypeScript (ts_ls), and Lua (lua_ls)
- **Fuzzy Finding**: Telescope with fzf backend
- **Autocompletion**: Blink.cmp with LuaSnip
- **Key Mappings**: Leader key is Space, test runner mapped to `<leader>s/t/a/l`

### Window Management (Hammerspoon)
- `Cmd+Ctrl+H`: Move window to left half and other windows to right
- `Cmd+Ctrl+L`: Move window to right half and other windows to left  
- `Cmd+Ctrl+Return`: Maximize current window

**Note**: Hammerspoon config references a missing `wincmds` module that should be created or removed.

### Git Workflow
- Uses concise aliases (a=add, co=checkout, ci=commit, etc.)
- Auto-rebasing on pull enabled
- Global gitignore for project-specific files (.exrc, .projections.json)

### Directory Navigation
- **Fish**: Uses `zoxide` with `j` command
- **Zsh**: Uses `fasd` with `j` command
Both provide frecency-based directory jumping.

## Special Configurations

- **Project-specific Vim configs**: Enabled via `.exrc` files (with security enabled)
- **vim-projectionist**: Uses `.projections.json` for project navigation
- **Terminal Integration**: Fish integrates with Zellij when using Ghostty terminal