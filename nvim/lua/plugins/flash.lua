return {
  "folke/flash.nvim",
  event = "VeryLazy",
  ---@type Flash.Config
  opts = {
    modes = {
      -- `t`/`T` stay: their off-by-one landing is what
      -- makes `dt,` work, and no labelled jump reproduces it. `;`/`,` repeat them.
      char = { keys = { "f", "F", "t", "T", ";", "," } },
    },
  },
  keys = {
    -- A replacement: vim's `s` is `cl`, which still does its job. It reaches the
    -- window instead of the line and labels the candidates instead of making you
    -- repeat `;`.
    { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
    -- Same search, one scope wider: `s` names a position by the characters at it,
    -- `S` names the structures themselves. There is no pattern to type -- every
    -- text object on screen is labelled the moment it fires, and the pick
    -- selects that node (config/node_pick.lua).
    -- Also a replacement -- vim's S is `cc`, which still does its job.
    --
    -- `S` was flash's own treesitter(), which labels the cursor's ancestors
    -- rather than the screen. Those ancestors are on screen and carry labels
    -- here too, so picking one still selects outward -- what is gone is
    -- repeating the key to step out one node at a time. Nothing calls
    -- treesitter() any more.
    { "S", mode = { "n", "x", "o" }, function() require("config.node_pick").pick() end, desc = "Pick Node" },
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
