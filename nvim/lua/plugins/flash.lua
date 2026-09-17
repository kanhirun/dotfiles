return {
  "folke/flash.nvim",
  event = "VeryLazy",
  ---@type Flash.Config
  opts = {
    modes = {
      -- `f` and `F` are the jumps below, so flash must not also claim them for
      -- its enhanced f/t motions. The rest keep their labels; `;`/`,` repeat them.
      char = { keys = { "t", "T", ";", "," } },
    },
  },
  keys = {
    -- Shadows vim's f. Flash's jump is find-by-characters across the window,
    -- so the one-line `f{char}` is a special case of it.
    { "f", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
    -- Same find, one scope wider: the pattern still matches characters, but the
    -- label lands on a treesitter node enclosing the match, window-wide. Shadows
    -- vim's F, which `f` already subsumes -- backwards-find-on-this-line is a
    -- special case of find-by-characters across the whole window.
    { "F", mode = { "n", "x", "o" }, function() require("flash").treesitter_search() end, desc = "Flash Treesitter Search" },
    -- No pattern: labels only the nodes enclosing the cursor.
    { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
    -- Labels every foldable node in the window; the pick becomes a manual
    -- fold (config/fold_pick.lua). Bare `z` is vim's fold prefix, so this
    -- sits inside it. Shadows zs, horizontal scroll, which only matters
    -- with nowrap.
    { "zs", mode = "n", function() require("config.fold_pick").pick("node") end, desc = "Fold Pick" },
    -- Shift widens scope: zs folds one node, zS folds every node at the
    -- picked nesting level. Labels are digits, so `3` reads as "level 3".
    { "zS", mode = "n", function() require("config.fold_pick").pick("level") end, desc = "Fold Pick Level" },
    -- { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
    -- { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
  },
}
