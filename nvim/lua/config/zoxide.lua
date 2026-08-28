-- zoxide only learns directories from its shell hooks (`zoxide init zsh`), so
-- anything you reach from inside nvim is invisible to it unless we say so.
-- Everything that records a directory goes through M.add.
local M = {}

--- Record a directory in zoxide's frecency database.
--- @param path string absolute or cwd-relative directory path
function M.add(path)
  if not path or path == '' or vim.fn.executable 'zoxide' ~= 1 then
    return
  end

  -- Normalize before storing: pickers hand us shapes like `infra`, `./infra`
  -- or `<cwd>/./infra`, and a trailing slash makes zoxide keep a second entry
  -- for the same directory. `:p` resolves all of that; the gsub drops the
  -- trailing slash `:p` adds to directories.
  local dir = (vim.fn.fnamemodify(path, ':p'):gsub('/$', ''))

  -- Fire and forget: a blocking :wait() here would stall every jump.
  vim.system { 'zoxide', 'add', dir }
end

return M
