return {
  "folke/flash.nvim",
  event = "VeryLazy",
  ---@type Flash.Config
  opts = {
    modes = {
      -- `f` and `F` are the jumps below, so flash must not also claim them for
      -- its enhanced f/t motions. `t`/`T` stay: their off-by-one landing is what
      -- makes `dt,` work, and no labelled jump reproduces it. `;`/`,` repeat them.
      char = { keys = { "t", "T", ";", "," } },
    },
  },
  keys = {
    -- An enhancement, not a replacement: vim's `f` means "move to text I name"
    -- and so does this. It reaches the window instead of the line and labels the
    -- candidates instead of making you repeat `;`. Nothing about `f` became false.
    { "f", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
    -- Same find, one scope wider: `f` names a position by the characters at it,
    -- `F` names the structures themselves. There is no pattern to type -- every
    -- text object on screen is labelled the moment it fires, and the pick
    -- selects that node (config/node_pick.lua).
    -- This one IS a replacement -- vim's F meant backwards-find-on-this-line --
    -- and it is only affordable because the bidirectional `f` above already
    -- absorbed that job, so the capability moved rather than disappeared.
    --
    -- `S` was flash's own treesitter(), which labels the cursor's ancestors
    -- rather than the screen. Those ancestors are on screen and carry labels
    -- here too, so picking one still selects outward -- what is gone is
    -- repeating the key to step out one node at a time. Nothing calls
    -- treesitter() any more and `S` is vim's substitute-line again.
    { "F", mode = { "n", "x", "o" }, function() require("config.node_pick").pick() end, desc = "Pick Node" },
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
