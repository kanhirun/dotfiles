-- ================ Key Mappings ==========================

-- Clear search highlights with //
vim.keymap.set('n', '//', ':noh<CR>', { silent = true })

-- Make 0 go to first character rather than beginning of line
vim.keymap.set('n', '0', '^', { noremap = true })
vim.keymap.set('n', '^', '0', { noremap = true })

-- ================ Terminal Escape =======================
-- Esc leaves terminal mode, which costs less than it looks like it should.
-- Snacks installs its own <Esc> on its terminals BUFFER-LOCALLY -- a 200ms
-- double-tap that passes a single press straight through to the program -- and
-- buffer-local beats global, so Claude's pane and the <C-Space> terminal are
-- untouched and keep Esc for interrupt. This governs plain :terminal buffers only,
-- where nothing is competing for the key. Vim's own <C-\><C-n> still works
-- everywhere as well.
vim.keymap.set('t', '<Esc>', '<C-\\><C-n>', { desc = 'Go to Normal mode' })

-- ================ Suspend ===============================
-- <C-z> suspends Neovim from every mode, as it already does in Normal. Unmapped
-- in terminal mode it is forwarded to the job, and Claude Code answers 0x1A by
-- SIGTSTP-ing itself -- with no shell on that PTY to `fg` it, the pane just
-- goes dead. Insert mode has no default for it since 'insertmode' was removed.
-- Global, so it also covers Claude's pane and the shell: neither Snacks nor
-- claudecode binds the key buffer-locally.
vim.keymap.set({ 'i', 't' }, '<C-z>', '<Cmd>suspend<CR>', { desc = 'Suspend Neovim' })

-- Shift makes it a different key, not the same one. Ghostty speaks the kitty
-- keyboard protocol, so Neovim reads <C-S-Z> as its own keycode rather than
-- folding it into <C-z>, and it has no default binding in any mode -- including
-- Normal, where plain <C-z> suspends. In terminal mode it is then forwarded to
-- the job as bare 0x1A, which is the dead-pane case above. Hence every mode
-- here, not just the two.
vim.keymap.set({ 'n', 'v', 'o', 'i', 't' }, '<C-S-z>', '<Cmd>suspend<CR>', { desc = 'Suspend Neovim' })

-- ================ Terminal in a Tab =====================
-- <C-Space> echoes the Space leader, is unclaimed by vim, blink.cmp, oil,
-- fugitive and telescope, and terminals send it as NUL, so it survives
-- terminal mode with no kitty keyboard protocol support. Every mode, like
-- <C-]>, so it also reaches from inside Claude's pane and from another shell.
--
-- A tab, not a pane. Nothing here shares the screen with the editor, so this is
-- a plain :terminal rather than a Snacks one: it carries no b:snacks_terminal,
-- the one-pane-at-a-time rule in terminal.lua ignores it, and the global t-mode
-- <Esc> above governs it. <leader>tt is the twin, bound to the same function.
local function terminal_tab()
  vim.cmd.tabnew()
  vim.cmd.terminal()
  vim.cmd.startinsert()
end

vim.keymap.set({ 'n', 'i', 'v', 'x', 't' }, '<C-Space>', terminal_tab, { desc = 'Terminal in a new tab' })
vim.keymap.set('n', '<leader>tt', terminal_tab, { desc = 'Terminal in a new tab' })

-- ================ Custom Commands =======================
vim.api.nvim_create_user_command('Projections', 'edit .projections.json', {})
