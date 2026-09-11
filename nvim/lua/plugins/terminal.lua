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
        function() Snacks.terminal.toggle() end,
        mode = { "n", "i", "v", "x", "t" },
        desc = "Toggle terminal",
      },
    },
  }
}
