local M = {}

local LIMIT = 50
local PATH = vim.fn.stdpath 'state' .. '/symbol_history.json'

local function load()
  local ok, lines = pcall(vim.fn.readfile, PATH)
  if not ok or #lines == 0 then
    return {}
  end
  local decoded, data = pcall(vim.json.decode, table.concat(lines, '\n'))
  if not decoded or type(data) ~= 'table' then
    return {}
  end
  return data
end

local function save(data)
  vim.fn.mkdir(vim.fn.fnamemodify(PATH, ':h'), 'p')
  vim.fn.writefile({ vim.json.encode(data) }, PATH)
end

local function identifier(text)
  local name = text:match '^%[.-%]%s+(.*)$' or text
  return name:match '[%w_$]+$' or name
end

local function file_lines(filename, cache)
  if cache[filename] == nil then
    local bufnr = vim.fn.bufnr(filename)
    if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
      cache[filename] = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    elseif vim.uv.fs_stat(filename) then
      cache[filename] = vim.fn.readfile(filename)
    else
      cache[filename] = false
    end
  end
  return cache[filename]
end

local function relocate(item, cache)
  local lines = file_lines(item.filename, cache)
  if not lines then
    return nil
  end
  local pattern = '%f[%w_$]' .. vim.pesc(identifier(item.text)) .. '%f[^%w_$]'
  local best
  for lnum, line in ipairs(lines) do
    if line:find(pattern) and (not best or math.abs(lnum - item.lnum) < math.abs(best - item.lnum)) then
      best = lnum
    end
  end
  if not best then
    return nil
  end
  local col = item.col
  if best ~= item.lnum then
    col = (lines[best]:find(pattern)) or 1
  end
  return { filename = item.filename, lnum = best, col = col, text = item.text, kind = item.kind }
end

function M.record(item)
  if not item or not item.filename or not item.text then
    return
  end
  local cwd = vim.uv.cwd()
  local data = load()
  local filename = vim.fs.normalize(vim.fn.fnamemodify(item.filename, ':p'))
  local kept = {
    { filename = filename, lnum = item.lnum, col = item.col, text = item.text, kind = item.kind },
  }
  for _, old in ipairs(data[cwd] or {}) do
    if #kept >= LIMIT then
      break
    end
    if not (old.filename == filename and old.text == item.text) then
      table.insert(kept, old)
    end
  end
  data[cwd] = kept
  save(data)
end

function M.list()
  local cache, found = {}, {}
  for _, item in ipairs(load()[vim.uv.cwd()] or {}) do
    local current = relocate(item, cache)
    if current then
      table.insert(found, current)
    end
  end
  return found
end

return M
