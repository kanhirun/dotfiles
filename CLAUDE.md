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

The doc is in two books. **Book One (Theory)** derives the architecture from the
mechanics of pressing keys and names no plugins. **Book Two (Implementation)** is the
as-built keymap — every binding actually installed, audited against the theory, with
deviations stated rather than hidden. Book Two is the authoritative inventory; the
summary below is orientation only.

> **Maintenance rule — this is not optional.** Any change to a key mapping under
> `nvim/` is incomplete until the artifact is updated in the same session. Read it with
> the Artifact tool using the URL above, edit that version, and republish to the same
> URL. Never publish a second artifact; never let the code change land alone.
>
> - A binding added, moved, removed or re-scoped → update Book Two's inventory row.
> - A binding that does not follow from an axiom → record it in Book Two's deviations,
>   with the reason. A deviation that is written down is fine; one that is silent is the
>   failure this whole document exists to prevent.
> - A new *rule* or a rule that changed → Book One, as an axiom or an amendment to one.
>   Never state a principle only in this file.
> - A question you could not settle → Book One, Part VI, as an open fork. Do not guess
>   and do not leave it out.

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
  `<C-s>`/`<leader>sS`, `<C-f>`/`<leader>fF`.
- **Shift widens scope, and means nothing else.** `<leader>ss` document →
  `<leader>sS` workspace; `<leader>sx` buffer diagnostics → `<leader>sX` project;
  `<leader>ff` recent files → `<leader>fF` every file. Bare
  `f` finds by text, `F` finds the text object enclosing the match — same pattern, one
  scope wider.
- **Shadow freely to enhance, deliberately to replace.** An *enhancement* keeps a vim
  key's meaning and widens its reach: flash on `f` still means "move to text I name," so
  nothing you knew about `f` became false and no justification is owed. A *replacement*
  puts a different meaning on the key, costs a default, and owes an account of where
  that job went — `F` is a replacement, acceptable only because bidirectional
  window-wide `f` already absorbed backwards-find-on-this-line. `t` and `T` are left
  alone because nothing else does their job. Record which kind a change is.
- **A bare key is not vacant real estate.** Leaving a slot to vim is a legitimate
  outcome; `s` is unbound on purpose.
- **Legacy control bytes only.** Zellij sits between the terminal and Neovim, so a
  chord must survive without kitty keyboard protocol support: `<C-Space>` (NUL),
  `<C-\>` (0x1C), `<C-]>` (0x1D), `<C-q>` (0x11). Note that **`<C-[>` is byte 0x1B — it
  *is* `<Esc>`** and cannot be bound independently.

Namespaces in use: `<leader>s` search · `<leader>r` refactor · `<leader>t` test/toggle ·
`<leader>g` git · `<leader>c` Claude. `<C-]>` toggles Claude and `<C-\>` opens a
terminal in a new tab, both from any mode; with a visual selection, `<C-]>` sends it to
Claude instead. `<C-Space>` returns to Normal mode from every mode and is the only way
out of terminal mode: `<Esc>` is bound nowhere and belongs to the program in every
terminal, which is what Snacks' buffer-local double-tap on Claude's pane already forced.
`<C-\>` is a replacement — it makes vim's own `<C-\><C-n>` and `<C-\><C-o>` untypable,
and stops forwarding the tty quit byte to a job, which is why `<C-Space>` had to take
over the first of those. Only one Snacks terminal pane is ever open at a time: showing
one hides any other (a `BufWinEnter` rule in `terminal.lua`). The `<C-\>` tab is a plain
`:terminal` and that rule ignores it. `<C-q>` toggles oil in a split beside the current
buffer (twin of `<leader>-`). `<C-f>`, `<C-j>` and `<C-q>` reach from inside both panes
and step to an editor window first (`config/panes.lua`), so a picked file or directory
never replaces a pane; from inside a pane they also move it to the right half of the
screen, so the file and the pane share it 50/50 side by side. Claude is already on the
right and is only narrowed; the shell leaves its bottom split for a full-height column
until it is next hidden.

Nouns keep one letter across every position they appear in. Diagnostics are `x`:
`g]`/`g[` move between them, `<leader>sx` lists them, `<leader>rx` fixes the one under
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