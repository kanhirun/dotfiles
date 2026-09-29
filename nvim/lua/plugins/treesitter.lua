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
        end, { desc = (key == "af" and "[a]round" or "[i]nside") .. " a [f]unction" })
      end
      local class_captures = { go = "@type" }
      for key, part in pairs({ ac = ".outer", ic = ".inner" }) do
        vim.keymap.set({ "x", "o" }, key, function()
          select.select_textobject((class_captures[vim.bo.filetype] or "@class") .. part, "textobjects")
        end, { desc = (key == "ac" and "[a]round" or "[i]nside") .. " a [c]lass" })
      end

      local move = require("nvim-treesitter-textobjects.move")

      local function test_ranges(buf)
        local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
        local query = lang and vim.treesitter.query.get(lang, "textobjects")
        if not query then
          return {}
        end
        local root = vim.treesitter.get_parser(buf, lang):parse()[1]:root()
        local ranges, seen = {}, {}
        for _, match in query:iter_matches(root, buf, 0, -1) do
          for id, nodes in pairs(match) do
            if query.captures[id] == "test.outer" then
              for _, node in ipairs(nodes) do
                local key = table.concat({ node:range() }, ":")
                if not seen[key] then
                  seen[key] = true
                  ranges[#ranges + 1] = { node:range() }
                end
              end
            end
          end
        end
        return ranges
      end

      local function same(a, b)
        return a[1] == b[1] and a[2] == b[2] and a[3] == b[3] and a[4] == b[4]
      end

      local function contains(outer, inner)
        return not same(outer, inner)
          and (outer[1] < inner[1] or (outer[1] == inner[1] and outer[2] <= inner[2]))
          and (outer[3] > inner[3] or (outer[3] == inner[3] and outer[4] >= inner[4]))
      end

      local function enclosing(ranges, range)
        local best
        for _, r in ipairs(ranges) do
          if contains(r, range) and (not best or contains(best, r)) then
            best = r
          end
        end
        return best
      end

      local function select_tests()
        local count = vim.v.count1
        select.select_textobject("@test.outer", "textobjects")
        if count == 1 then
          return
        end
        local first = vim.fn.getpos("v")
        local ranges = test_ranges(0)
        local selected
        for _, r in ipairs(ranges) do
          if r[1] == first[2] - 1 and r[2] == first[3] - 1 then
            selected = r
          end
        end
        if not selected then
          return
        end
        local parent = enclosing(ranges, selected)
        local siblings = {}
        for _, r in ipairs(ranges) do
          local up = enclosing(ranges, r)
          if (up == parent or (up and parent and same(up, parent))) and r[1] > selected[3] then
            siblings[#siblings + 1] = r
          end
        end
        table.sort(siblings, function(a, b)
          return a[1] < b[1]
        end)
        local last = siblings[math.min(count - 1, #siblings)]
        if last then
          vim.api.nvim_win_set_cursor(0, { last[3] + 1, math.max(last[4] - 1, 0) })
        end
      end

      local function outside_diff(key, go)
        if vim.wo.diff and key:sub(1, 1) ~= "g" then
          vim.cmd.normal({ vim.v.count1 .. key, bang = true })
        else
          go()
        end
      end

      vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
        group = vim.api.nvim_create_augroup("test_textobjects", { clear = true }),
        pattern = { "*_test.go", "*.test.[jt]s", "*.spec.[jt]s", "*.test.[jt]sx", "*.spec.[jt]sx" },
        callback = function(ev)
          vim.keymap.set({ "x", "o" }, "at", select_tests, { buffer = ev.buf, desc = "[a]round a [t]est" })
          vim.keymap.set({ "x", "o" }, "it", function()
            select.select_textobject("@test.inner", "textobjects")
          end, { buffer = ev.buf, desc = "[i]nside a [t]est" })
          for key, object in pairs({ ac = "@describe.outer", ic = "@describe.inner" }) do
            vim.keymap.set({ "x", "o" }, key, function()
              select.select_textobject(object, "textobjects")
            end, { buffer = ev.buf, desc = (key == "ac" and "[a]round" or "[i]nside") .. " a [c]ontext" })
          end
          for key, go in pairs({
            gt = { move.goto_next_start, "[g]o to [t]est" },
            gT = { move.goto_previous_start, "[g]o to previous [T]est" },
            ["]t"] = { move.goto_next_end, "forward to a [t]est's end" },
            ["[t"] = { move.goto_previous_end, "back to a [t]est's end" },
          }) do
            vim.keymap.set({ "n", "x", "o" }, key, function()
              go[1]("@it.outer", "textobjects")
            end, { buffer = ev.buf, desc = go[2] })
          end
          for key, go in pairs({
            gc = { move.goto_next_start, "[g]o to [c]ontext" },
            gC = { move.goto_previous_start, "[g]o to previous [C]ontext" },
            ["]c"] = { move.goto_next_end, "forward to a [c]ontext's end" },
            ["[c"] = { move.goto_previous_end, "back to a [c]ontext's end" },
          }) do
            vim.keymap.set({ "n", "x", "o" }, key, function()
              outside_diff(key, function()
                go[1]("@describe.outer", "textobjects")
              end)
            end, { buffer = ev.buf, desc = go[2] })
          end
        end,
      })
      for key, go in pairs({
        gc = { move.goto_next_start, "[g]o to [c]lass" },
        gC = { move.goto_previous_start, "[g]o to previous [C]lass" },
        ["]c"] = { move.goto_next_end, "forward to a [c]lass's end" },
        ["[c"] = { move.goto_previous_end, "back to a [c]lass's end" },
      }) do
        vim.keymap.set({ "n", "x", "o" }, key, function()
          outside_diff(key, function()
            go[1]((class_captures[vim.bo.filetype] or "@class") .. ".outer", "textobjects")
          end)
        end, { desc = go[2] })
      end
      for key, go in pairs({
        gf = { move.goto_next_start, "[g]o to [f]unction" },
        gF = { move.goto_previous_start, "[g]o to previous [F]unction" },
        ["]f"] = { move.goto_next_end, "forward to a [f]unction's end" },
        ["[f"] = { move.goto_previous_end, "back to a [f]unction's end" },
      }) do
        vim.keymap.set({ "n", "x", "o" }, key, function()
          go[1]("@function.outer", "textobjects")
        end, { desc = go[2] })
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
