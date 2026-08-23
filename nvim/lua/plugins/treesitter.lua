return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main", -- master is frozen at Nvim 0.11; main is required for 0.12+
    lazy = false, -- the main branch does not support lazy-loading
    build = ":TSUpdate",
    config = function()
      local ts = require("nvim-treesitter")

      -- Parsers and queries are installed under stdpath("data")/site, which is
      -- already on the runtimepath, so nothing else needs to know about them.
      ts.setup()

      -- Replaces `ensure_installed`. install() skips parsers that are already
      -- present, so this is cheap on subsequent startups and runs async.
      ts.install({
        "go",
        "gomod",
        "gowork",
        "gosum",
        "lua",
        "python",
        "typescript",
        "tsx",
        "markdown", -- used by LSP hover floats
        "markdown_inline",
      })

      -- Replaces `highlight = { enable = true }` and `indent = { enable = true }`.
      -- On main, the plugin only installs parsers; enabling treesitter per
      -- buffer is now your job.
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("treesitter_start", { clear = true }),
        callback = function(ev)
          local lang = vim.treesitter.language.get_lang(ev.match)
          -- language.add() returns nil when no parser is installed for `lang`,
          -- which keeps this a no-op for filetypes we have no parser for.
          if not lang or not vim.treesitter.language.add(lang) then
            return
          end
          vim.treesitter.start(ev.buf, lang)
          vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-context",
    config = function()
      require('treesitter-context').setup {
        max_lines = 1,
        mode = 'topline'
      }
    end
  },
}
