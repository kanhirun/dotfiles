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

- **Fish**: Primary config in `fish/config.fish` — editor, PATH, and the same zoxide/pyenv/nodenv/direnv/starship initialization as zsh. Empty `functions/` and `completions/` directories.
- **Zsh**: Config in `zshrc` at the repo root — this is the file `~/.zshrc` symlinks to. Uses starship for the prompt, zoxide for directory jumping, and pyenv/goenv/nodenv/rbenv/direnv. No framework. Records every session to a transcript — see Shell Transcripts below. Note `bindkey -e` is load-bearing: `EDITOR=nvim` contains "vi", which otherwise makes zsh silently select vi keybindings.

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
  twin so the two cannot drift apart. See `telescope.lua`: `<C-s>`/`<leader>ss`,
  `<C-S-s>`/`<leader>sS`, `<C-f>`/`<leader>ff`, `<C-S-f>`/`<leader>fF`,
  `<C-p>`/`<leader>fp`, `<C-S-p>`/`<leader>fP`. Shift on
  the chord widens scope the same way Shift on the leader letter does.
- **Shift widens scope, and means nothing else.** `<leader>ss` document →
  `<leader>sS` workspace; `<leader>sx` buffer diagnostics → `<leader>sX` project;
  `<leader>ff` folders zoxide ranks → `<leader>fF` every folder;
  `<leader>fp` recent files → `<leader>fP` every file. Bare
  `s` searches by text, `S` labels every text object on screen — same pattern, one
  scope wider, and the same letter as the `<leader>s` search group. `S`'s
  inventory is the language's `folds.scm`, gathered by range rather than by line (`config/node_pick.lua`, sharing `fold_pick`'s candidates);
  labelling every treesitter node instead would need ~255 labels on a 40-line
  screen against flash's 52. `nvim/after/queries/*/folds.scm` widens that
  inventory where upstream is too narrow — a call taking a function literal, so
  `describe`, `it`, `Describe`, `It` and `t.Run` are reachable by name rather
  than by their argument list. A dense TypeScript spec passes 52 candidates
  without them; the labels run out furthest from the cursor first.
- **Shadow freely to enhance, deliberately to replace.** An *enhancement* keeps a vim
  key's meaning and widens its reach: flash's char mode on `f`, `F`, `t` and `T` still
  means "move to this character," so nothing you knew about them became false and no
  justification is owed. A *replacement* puts a different meaning on the key, costs a
  default, and owes an account of where that job went — `s` and `S` are replacements,
  affordable because vim's own `s` and `S` are only `cl` and `cc`, which still work.
  Record which kind a change is.
- **A bare key is not vacant real estate.** Leaving a slot to vim is a legitimate
  outcome, even when a mnemonic wants it filled.
- **Legacy control bytes only.** Zellij sits between the terminal and Neovim, so a
  chord must survive without kitty keyboard protocol support: `<C-Space>` (NUL),
  `<C-\>` (0x1C), `<C-]>` (0x1D), `<C-q>` (0x11). Note that **`<C-[>` is byte 0x1B — it
  *is* `<Esc>`** and cannot be bound independently. Two bindings now break this
  rule deliberately, `<C-S-Z>` and `<C-S-[>`: Ctrl with Shift has no legacy byte,
  so Ghostty reports each as its own keycode and a terminal without the protocol
  simply never delivers them. That is a clean failure rather than a collision —
  `<C-S-[>` does *not* decay to `<Esc>` the way `<C-[>` would — which is what
  makes the exception affordable now that the Zellij layer is gone. `<C-S-f>`,
  `<C-S-p>` and `<C-S-s>` are the third, fourth and fifth, twins of
  `<leader>fF`, `<leader>fP` and `<leader>sS`. Without the protocol they fold
  into `<C-f>`, `<C-p>` and `<C-s>`, which is harmless because each lands on a
  picker from the same pair.

Namespaces in use: `<leader>s` search · `<leader>r` refactor · `<leader>t` test/toggle ·
`<leader>g` git · `<leader>c` Claude. `<C-]>` toggles Claude and `<C-\>` toggles a
terminal tab, both from any mode; with a visual selection, `<C-]>` sends it to
Claude instead. Claude always opens on the right. Its width depends on the
layout it opens into: 3/5 of the screen beside a single editor column, and a
third when two or more editor columns already sit side by side, with the editors
evened out so the screen splits into equal thirds. Windows with `winfixwidth` —
the oil drawers — do not count as columns, so a drawer beside a file still gets
the 3/5 pane. Only the toggle does this; a send opens through `ClaudeCodeSend`'s
configured default, which is the 3/5 width on the right. `<C-Space>` returns to
Normal mode from every mode and is the only way
out of terminal mode: `<Esc>` is bound nowhere and belongs to the program in every
terminal, which is what Snacks' buffer-local double-tap on Claude's pane already forced.
`<C-\>` is a replacement — it makes vim's own `<C-\><C-n>` and `<C-\><C-o>` untypable,
and stops forwarding the tty quit byte to a job, which is why `<C-Space>` had to take
over the first of those. Only one Snacks terminal pane is ever open at a time: showing
one hides any other (a `BufWinEnter` rule in `terminal.lua`). The `<C-\>` tab is a plain
`:terminal` and that rule ignores it. `<C-q>` toggles oil in a split beside the current
buffer (twin of `<leader>-`), and `<C-S-[>` toggles a narrower one pinned to the
screen's left edge (twin of `<leader>_`). The difference is `leftabove` against
`topleft`: the first is relative to the window you are in, so from a right-hand
split it lands mid-screen, and the second always reaches the edge. Either chord
closes whichever drawer is open, so the two never stack. `_` marks a variant
rather than a wider scope, which is the one place Shift means something else.
`<C-f>`, `<C-S-f>`, `<C-p>`, `<C-S-p>` and `<C-q>` reach from inside both panes
and step to an editor window first (`config/panes.lua`), so a picked file or directory
never replaces a pane; from inside a pane they also move it to the right half of the
screen, so the file and the pane share it 50/50 side by side. Claude is already a
vertical split on the right and is only narrowed; the shell
leaves its bottom split for a full-height column until it is next hidden.

Nouns keep one letter across every position they appear in. Diagnostics are `x`:
`]x`/`[x` move between them, `<leader>sx` lists them, `<leader>rx` fixes the one under
the cursor. Adding a binding for an existing noun should reuse its letter. The
bracket is the direction and the letter is the noun, so a new noun's motion is
guessable rather than looked up; `g]`/`g[` held this before and taught nothing.

**Setup this repo does not capture**: Caps Lock is remapped to Ctrl via macOS
System Settings. cmux is the terminal and sits directly under Neovim — there is
no multiplexer in between, and `~/.config/ghostty/config` does not exist, so
cmux's built-in Ghostty defaults apply. Both affect which chords are reachable;
see the note on legacy control bytes above, which was written for a Zellij layer
that is no longer installed.

### Window Management (Hammerspoon)
- `Cmd+Ctrl+H`: Move window to left half and other windows to right
- `Cmd+Ctrl+L`: Move window to right half and other windows to left  
- `Cmd+Ctrl+Return`: Maximize current window

**Note**: Hammerspoon config references a missing `wincmds` module that should be created or removed.

### Shell Transcripts (`zshrc`)

Every interactive zsh records itself with `script` to
`~/.local/state/shell-logs/<dirname>-<surface>-<timestamp>.log` and deletes the log
when it exits. The block sits at the top of `zshrc`; its comments explain each
line. What follows is the shape, and what breaks it.

- **Two shells per tab.** The outer zsh sources `zshrc`, starts `script`, waits,
  then exits. `script` starts the inner zsh you type into, which sources `zshrc`
  again and falls through because `$SHELL_TRANSCRIPT` is already set. Every prompt
  you see is the inner one.
- **`script` must stay a child, never an `exec`.** The cleanup trap runs in the
  outer shell after `script` returns. `exec script` reads like a tidy-up and
  silently ends deletion.
- **Not recorded:** shells under Claude Code (`$CLAUDECODE`), inside Neovim's
  terminal (`$NVIM`) — so the `<C-\>` tab and the Snacks pane never are — and
  anything started with `NO_TRANSCRIPT=1`. Fish does not record at all.
- **The consumer side is `claude/CLAUDE.md`.** It tells Claude where logs are, how
  to read them narrowly, and that they vanish with their shell. A change here to
  naming, location, retention or the exclusion list is incomplete until that file
  says the same thing.

#### Naming, and `cmux/shell-log-links`

`<dirname>` is the basename of the directory the shell started in, so tabs on one
checkout are indistinguishable by it — the name that tells them apart is the cmux
tab title, and that lives in cmux. `<surface>` is the first eight hex digits of
`$CMUX_SURFACE_ID`, present only under cmux, and it is the join key.

`cmux/automations.json` is symlinked to `~/.cmuxterm/automations.json` and runs
the handler once per event through cmux's own rules engine, which is why there is
no daemon and no launchd agent: cmux owns the lifecycle, and nothing runs while
cmux is closed. Reload rules with `cmux automation reload`, list them with
`cmux automation list`.

- **The transcript never moves.** `script` holds an open descriptor for the life
  of the session; only the symlink is swapped. Renaming the file instead would
  put that descriptor in question for no gain.
- **Each run is a fresh process**, so what a follower would hold in memory lives
  in `~/.cache/cmux/shell-log-links.json`, taken under `flock` because cmux can
  fire several rules at once.
- **There is no rename event.** Of every event cmux emits, only
  `workspace.created` and `workspace.selected` carry a title, so a tab renamed
  mid-session keeps its old link until you switch to it again. `--replay N`
  backfills state for tabs open since before the rule existed.
- **`--reap` is off.** It would delete a transcript on `surface.closed`, covering
  the `kill -9` case the exit trap cannot, but a wrong surface-to-file mapping
  would delete a live log.

**Setup this repo does not capture**, once per machine:

```bash
ln -s ~/workspace/dotfiles/cmux/automations.json ~/.cmuxterm/automations.json
cmux automation reload && cmux automation list      # expect two enabled rules
~/workspace/dotfiles/cmux/shell-log-links --replay 1200   # backfill tab titles
tmutil addexclusion ~/.local/state/shell-logs
```

Without the exclusion, Time Machine copies transcripts into snapshots the exit
trap cannot reach. `~/.config/cmux/cmux.json` is deliberately not tracked: it is
cmux's own generated template, and nothing in it is set.

### Claude Code (`claude/`)

Global config, symlinked into place rather than copied — `~/.claude/CLAUDE.md` and
each `~/.claude/skills/<name>` point back here, so an edit through either path is the
same file:

```bash
ln -s ~/workspace/dotfiles/claude/CLAUDE.md ~/.claude/CLAUDE.md
ln -s ~/workspace/dotfiles/claude/skills/commit ~/.claude/skills/commit
```

Note the undotted directory: `.gitignore` excludes `.claude/`, which is this repo's own
project-local Claude state.

Only hand-written skills live here. `~/.claude/skills` also holds `synced/`, which
claude.ai rewrites, and marketplace installs symlinked out to `~/.agents/skills/`;
neither is this repo's to track. `perfectly-hedged` is deliberately excluded too — its
corpus is licensed course material and this repo is public.

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
- **vim-projectionist**: Uses `.projections.json` for project navigation. It is
  vendored at `nvim/vendor/vim-projectionist`, a copy of upstream `tpope/vim-projectionist`
  at `5ff7bf7` (2024-12-21), loaded by `dir =` in `nvim/lua/plugins/projectionist.lua`
  rather than fetched by lazy.nvim. The one addition is the `"match"` key
  (`:help projectionist-match`): a regex the glob's match (`{}`) must also satisfy,
  which is how `*.go` excludes `*_test.go`. It is distributed under Vim's license,
  which permits a modified public copy; that is the deliberate exception to keeping
  licensed material out of this repo, so do not remove it on those grounds.