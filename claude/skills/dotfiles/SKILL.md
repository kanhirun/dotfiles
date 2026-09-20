---
name: dotfiles
description: Change the personal dotfiles at ~/workspace/dotfiles — nvim keymaps and plugins, zsh, fish, git config and aliases, hammerspoon, starship, cmux, or Claude's own CLAUDE.md and skills — from inside any project. Use when the ask is about the editor, shell, or tooling rather than the code in front of you.
---

# Dotfiles

The repo is `~/workspace/dotfiles`. Work there. The current project is almost
certainly something else, so no path is relative to where this skill was invoked.

## Read CLAUDE.md before the first edit

`~/workspace/dotfiles/CLAUDE.md` is **not** loaded when this skill runs from
another project, and nothing in it is guessable from the code. It carries the
keyboard architecture, the maintenance rule that binds a keymap change to the
published artifact, which directories are symlinked, and why `.claude/` is
ignored while `claude/` is tracked. Read it, then edit.

## Edits are live

Every tracked config is symlinked into place, so writing a file in the repo
changes the running configuration — there is no install step and no copy to keep
in sync. What it does mean is that a change is not visible until the thing that
reads it reloads:

- `zshrc` — new shells only; the one you are in keeps the old config
- `nvim/` — restart Neovim, or `:source` the file if it is safe to re-run
- `claude/CLAUDE.md`, `claude/skills/` — next Claude Code session

Say which one applies. A change the user cannot see yet reads as a change that
did not work.

## The hook is the gate

`githooks/pre-commit` parses every Lua file and boots the Neovim config against
the staged tree. It is the reason history is bisectable. Never `--no-verify`; if
it is wrong, fix the hook.

Commit with the `commit` skill — it partitions the tree and takes the message
voice from hand-written commits rather than recent ones.

## The repo is public

`github.com/kanhirun/dotfiles`. Nothing licensed, private, or credential-shaped
goes in, and that includes fixtures and example output. When something is
excluded for this reason, say so in `CLAUDE.md` so the next session does not
helpfully add it back.
