return {
  "folke/flash.nvim",
  event = "VeryLazy",
  ---@type Flash.Config
  opts = {
    modes = {
      -- `f` is the jump below, so flash must not also claim it for its
      -- enhanced f/t motions. The others keep their labels; `;`/`,` repeat them.
      char = { keys = { "F", "t", "T", ";", "," } },
    },
  },
  keys = {
    -- Shadows vim's f. Flash's jump is find-by-characters across the window,
    -- so the one-line `f{char}` is a special case of it.
    { "f", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
    -- Type a pattern; every treesitter node enclosing each match gets a label,
    -- window-wide. `S` only reaches the nodes enclosing the cursor.
    { "s", mode = { "n", "x", "o" }, function() require("flash").treesitter_search() end, desc = "Flash Treesitter Search" },
    { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
    -- { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
    -- { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
  },
}
