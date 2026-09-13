return {
  -- Terminal toggle
  -- https://github.com/folke/snacks.nvim
  {
    "folke/snacks.nvim",
    -- claudecode.nvim already pulls snacks in as a dependency, but nothing ever
    -- calls setup() on it, so the `Snacks` global is nil. An explicit spec with
    -- opts is what defines it; without this the keymap below has to go through
    -- require("snacks") instead.
    opts = {
      terminal = {
        -- Snacks opens the terminal as a bottom split at height 0.4. Values
        -- below 1 are read as a fraction of the editor height, so 3/4 is three
        -- quarters of the screen.
        win = { height = 3 / 4 },
      },
    },
    keys = {
      -- Mirrors <C-]> in claudecode.lua: bound in every mode including `t`,
      -- so the chord that opens the terminal also closes it from inside.
      --
      -- <C-Space> echoes the Space leader and is unclaimed by Vim, blink.cmp,
      -- oil, fugitive and telescope. Terminals send it as NUL, so like <C-]>'s
      -- 0x1D it survives terminal mode with no kitty keyboard protocol support.
      {
        "<C-Space>",
        -- term_normal = false deletes snacks' own <Esc> handler for THIS terminal,
        -- letting the global t-mode <Esc> in config/keymaps.lua through. Snacks
        -- binds <Esc> buffer-locally to a 200ms double-tap, and buffer-local beats
        -- global, so without this a single <Esc> here does nothing.
        --
        -- Passed per call rather than in opts.terminal above, because that is
        -- shared configuration: claudecode.nvim opens its pane through the same
        -- Snacks.terminal, and Claude needs <Esc> for interrupt. This is a plain
        -- shell, so nothing here wants the key.
        function()
          Snacks.terminal.toggle(nil, { win = { keys = { term_normal = false } } })
        end,
        mode = { "n", "i", "v", "x", "t" },
        desc = "Toggle terminal",
      },
    },
  }
}
