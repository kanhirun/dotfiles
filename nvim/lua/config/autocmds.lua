-- ================ zoxide integration ========================
-- Mirror every :cd into zoxide so `<C-j>` here and `j` in the shell
-- rank the same places. This covers oil's `` ` ``/`~` (actions.cd), the
-- <C-j> picker itself, and any manual :cd/:lcd/:tcd. Directory
-- navigation that does *not* change the cwd -- the <leader>fd picker -- calls
-- config.zoxide.add directly.
local zoxide = vim.api.nvim_create_augroup('zoxide', { clear = true })

vim.api.nvim_create_autocmd('DirChanged', {
  group = zoxide,
  pattern = '*',
  desc = 'Record the new cwd in zoxide',
  callback = function()
    require('config.zoxide').add(vim.v.event.cwd)
  end,
})

vim.api.nvim_create_autocmd('BufEnter', {
  group = zoxide,
  pattern = 'oil://*',
  desc = 'Record the directory oil is showing in zoxide',
  callback = function(args)
    require('config.zoxide').add(require('oil').get_current_dir(args.buf))
  end,
})

vim.api.nvim_create_autocmd('BufReadPost', {
  group = vim.api.nvim_create_augroup('restore_cursor', { clear = true }),
  desc = 'Put the cursor where it was when the file was last closed',
  callback = function(ev)
    local ft = vim.bo[ev.buf].filetype
    if vim.bo[ev.buf].buftype ~= '' or ft == 'gitcommit' or ft == 'gitrebase' then
      return
    end
    local line = vim.api.nvim_buf_get_mark(ev.buf, '"')[1]
    if line > 0 and line <= vim.api.nvim_buf_line_count(ev.buf) then
      vim.cmd 'normal! g`"'
    end
  end,
})

-- ================ reload files changed on disk ================
-- 'autoread' only reloads a buffer when checktime runs, and Neovim runs it on
-- its own only for the buffer being entered. A hidden buffer that Claude
-- rewrote stays stale, and gopls keeps checking open files against their
-- buffers, not the disk -- so the file you are in shows errors against code
-- that no longer exists. A bare :checktime claims to cover every buffer but
-- left a hidden one stale in testing; naming each buffer does reload it.
vim.api.nvim_create_autocmd({ 'FocusGained', 'TermLeave', 'BufEnter', 'CursorHold' }, {
  group = vim.api.nvim_create_augroup('reload_changed', { clear = true }),
  desc = 'Reload every buffer whose file changed on disk',
  callback = function()
    -- :checktime is an error inside the command-line window.
    if vim.fn.getcmdwintype() ~= '' then
      return
    end
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == ''
          and vim.api.nvim_buf_get_name(buf) ~= '' then
        vim.cmd('checktime ' .. buf)
      end
    end
  end,
})
