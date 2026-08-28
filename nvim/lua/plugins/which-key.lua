return {
  -- Popup showing possible completions for the key sequence you started typing
  -- https://github.com/folke/which-key.nvim
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      delay = 400,
      spec = {
        -- Labels for prefixes whose mappings live across several plugin specs.
        -- <leader>c is labelled in claudecode.lua, alongside the mappings.
        { "<leader>s", group = "Search (Telescope)" },
        { "<leader>g", group = "Goto/Symbols" },
      },
    },
    keys = {
      {
        "<leader>?",
        function() require("which-key").show({ global = false }) end,
        desc = "Buffer local keymaps",
      },
    },
  }
}
