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

-- ================ Custom Commands =======================
vim.api.nvim_create_user_command('Projections', 'edit .projections.json', {})
