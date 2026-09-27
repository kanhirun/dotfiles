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
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    config = function()
      require("nvim-treesitter-textobjects").setup({ select = { lookahead = true } })
      local select = require("nvim-treesitter-textobjects.select")
      for key, object in pairs({ af = "@function.outer", ["if"] = "@function.inner" }) do
        vim.keymap.set({ "x", "o" }, key, function()
          select.select_textobject(object, "textobjects")
        end, { desc = "Select " .. object })
      end

      local move = require("nvim-treesitter-textobjects.move")

      vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
        group = vim.api.nvim_create_augroup("test_textobjects", { clear = true }),
        pattern = { "*_test.go", "*.test.[jt]s", "*.spec.[jt]s", "*.test.[jt]sx", "*.spec.[jt]sx" },
        callback = function(ev)
          for key, object in pairs({ at = "@test.outer", it = "@test.inner" }) do
            vim.keymap.set({ "x", "o" }, key, function()
              select.select_textobject(object, "textobjects")
            end, { buffer = ev.buf, desc = "Select " .. object })
          end
          local function next_test()
            move.goto_next_start("@test.outer", "textobjects")
          end
          local function previous_test()
            move.goto_previous_start("@test.outer", "textobjects")
          end
          for _, key in ipairs({ "]t", "gt" }) do
            vim.keymap.set({ "n", "x", "o" }, key, next_test, { buffer = ev.buf, desc = "Next test" })
          end
          for _, key in ipairs({ "[t", "gT" }) do
            vim.keymap.set({ "n", "x", "o" }, key, previous_test, { buffer = ev.buf, desc = "Previous test" })
          end
        end,
      })
      for key, go in pairs({ ["]c"] = move.goto_next_start, ["[c"] = move.goto_previous_start }) do
        vim.keymap.set({ "n", "x", "o" }, key, function()
          if vim.wo.diff then
            vim.cmd.normal({ vim.v.count1 .. key, bang = true })
          else
            go("@class.outer", "textobjects")
          end
        end, { desc = key == "]c" and "Next class" or "Previous class" })
      end
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
