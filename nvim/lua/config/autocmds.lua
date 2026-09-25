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
