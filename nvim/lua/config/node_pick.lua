-- Labels every text object on screen, flash-style, and selects the one you
-- pick. The inventory is fold_pick's -- whatever the language's folds.scm
-- captures as @fold -- gathered by range instead of by line, so nodes sharing
-- their lines and nodes that fit on one both earn a label.
--
-- Labelling every treesitter node instead is not on: a forty-line screen of Go
-- carries around 255 distinct node ranges over 170 start positions, against
-- flash's 52 labels, and nested nodes sharing a start position cannot be told
-- apart by a label sitting on it. folds.scm is what brings the count back
-- inside the budget, and it does so per language.
--
-- after/queries/*/folds.scm extends that inventory where it is too narrow --
-- currently block-taking calls, so a test block is reachable by its name. A
-- dense TypeScript spec already exceeds the 52 labels without them, and the
-- candidates that lose out are the ones furthest from the cursor, since the
-- sort below hands out labels nearest-first.
local M = {}

-- Closest candidates to the cursor take the first labels, as flash does.
local function matcher(win, state)
  local Pos = require("flash.search.pos")
  local labels = state:labels()
  local cur = vim.api.nvim_win_get_cursor(win)[1]

  local items = require("config.fold_pick").candidates(win, { by_range = true })
  table.sort(items, function(a, b)
    local da, db = math.abs(a.first - cur), math.abs(b.first - cur)
    if da ~= db then
      return da < db
    end
    if a.first ~= b.first then
      return a.first < b.first
    end
    return a.col < b.col
  end)

  local ret = {}
  for _, it in ipairs(items) do
    local label = table.remove(labels, 1)
    if not label then
      break
    end
    ret[#ret + 1] = {
      win = win,
      pos = Pos({ it.first, it.col }),
      end_pos = Pos({ it.last, it.end_col }),
      label = label,
    }
  end
  return ret
end

-- Opens the picker without reading keys, so callers (and tests) can inspect
-- the labelled state. pick() is open() plus the key loop.
function M.open()
  local Config = require("flash.config")
  local Repeat = require("flash.repeat")
  return Repeat.get_state(
    "node_pick",
    Config.get({
      matcher = matcher,
      labeler = function() end,
      -- No action, so flash's own jump runs; pos = "range" makes the pick a
      -- visual selection of the node rather than a cursor move to its start,
      -- which is what lets `S` stand in for a text object after an operator.
      jump = { pos = "range" },
      -- max_length = 0: every key is a label, none is a search character.
      search = { multi_window = false, max_length = 0, incremental = false },
      -- inline: the label is inserted ahead of the node's first character
      -- rather than painted over the one before it, which at column 0 is the
      -- previous line. Uppercase labels stay on, unlike fold_pick: gathering
      -- by range roughly doubles the count, and a tall window of dense code
      -- passes 26, where a dropped candidate would defeat the whole point.
      label = { before = true, after = false, style = "inline" },
      prompt = { enabled = false },
    })
  )
end

function M.pick()
  M.open():loop({
    jump_on_max_length = false,
    abort = function()
      require("flash.util").exit()
    end,
  })
end

return M
