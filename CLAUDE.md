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
- **Zsh**: Config in `zshrc` at the repo root — this is the file `~/.zshrc` symlinks to. Uses starship for the prompt, zoxide for directory jumping, and pyenv/goenv/nodenv/rbenv/direnv. No framework. Note `bindkey -e` is load-bearing: `EDITOR=nvim` contains "vi", which otherwise makes zsh silently select vi keybindings.

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
- **Key Mappings**: Leader is Space. **Read the Keyboard Architecture below before adding or moving any binding.**

### Keyboard Architecture

Keymaps under `nvim/` follow a deliberate architecture rather than accumulating ad hoc.
It is documented in full at:

**[One Noun, Every Verb](https://claude.ai/code/artifact/e66c9011-6cf1-46ca-a8d9-822c6af29120)**

The rules that matter most when editing this config:

- **Three tiers.** Bare keys and the `g` / `[` / `]` namespaces are motion. Chords
  (`<C-x>`) are teleport — they must work in every mode, fire instantly, and never
  mutate. `<leader>` sequences are actions, discoverable through which-key.
- **No mapping is ever both a prefix and a leaf.** A key bound directly while a longer
  sequence shares its prefix stalls for `timeoutlen` (unset, so 1000ms). This was the
  defect behind the old `<leader>s` (TestNearest + `<leader>sd`) and `<leader>t`
  (TestFile + `<leader>th`). Check for this before binding anything.
- **The chord tier is closed.** Roughly a dozen slots exist, permanently, capped by
  vim's own reservations (`<C-o>`, `<C-i>`, `<C-u>`, `<C-d>`, `<C-r>`, `<C-v>`,
  `<C-w>`). Something new belongs on `<leader>`, not on a chord.
- **A chord is an alias, never a sole address.** Chords are invisible — nothing on
  screen reveals them. Each one binds the *same function object* as its `<leader>`
  twin so the two cannot drift apart. See `telescope.lua`: `<C-k>`/`<leader>ss`,
  `<C-l>`/`<leader>sS`, `<C-p>` and `<C-f>`/`<leader>sf`.
- **Shift widens scope, and means nothing else.** `<leader>ss` document →
  `<leader>sS` workspace; `<leader>sx` buffer diagnostics → `<leader>sX` project.
- **Legacy control bytes only.** Zellij sits between the terminal and Neovim, so a
  chord must survive without kitty keyboard protocol support: `<C-Space>` (NUL),
  `<C-\>` (0x1C), `<C-]>` (0x1D). Note that **`<C-[>` is byte 0x1B — it *is* `<Esc>`**
  and cannot be bound independently.

Namespaces in use: `<leader>s` search · `<leader>r` refactor · `<leader>t` test/toggle ·
`<leader>g` git · `<leader>c` Claude. `<C-]>` toggles Claude and `<C-Space>` toggles a
terminal, both from any mode; with a visual selection, `<C-]>` sends it to Claude
instead. Only one of those two panes is ever open: showing either hides the other (a
`BufWinEnter` rule in `terminal.lua`). `<C-p>` and `<C-j>` reach from inside both panes
and step to an editor window first, so a picked file or directory never replaces a
pane; picking one from inside a pane resizes the pane to half the screen along its own
axis (height for the bottom shell, width for Claude on the right), so the two share it
50/50.

Nouns keep one letter across every position they appear in. Diagnostics are `x`:
`]x`/`[x` move between them, `<leader>sx` lists them, `<leader>rx` fixes the one under
the cursor. Adding a binding for an existing noun should reuse its letter.

**Setup this repo does not capture**: Caps Lock is remapped to Ctrl via macOS System
Settings, and the Zellij and Ghostty configs live in `~/.config/` untracked. Both
affect which chords are reachable.

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
- **Zsh**: Uses `zoxide` with `j` command
Both provide frecency-based directory jumping.

## Special Configurations

- **Project-specific Vim configs**: Enabled via `.exrc` files (with security enabled)
- **vim-projectionist**: Uses `.projections.json` for project navigation
- **Terminal Integration**: Fish integrates with Zellij when using Ghostty terminal