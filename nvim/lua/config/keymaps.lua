-- ================ Key Mappings ==========================

-- Clear search highlights with //
vim.keymap.set('n', '//', ':noh<CR>', { silent = true })

-- Make 0 go to first character rather than beginning of line
vim.keymap.set('n', '0', '^', { noremap = true })
vim.keymap.set('n', '^', '0', { noremap = true })

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

-- ================ Universal Normal Mode =================
-- <C-Space> returns to Normal mode from wherever you are: one press, one key,
-- every mode. It is the only way out of terminal mode, deliberately. <Esc> is
-- bound nowhere and belongs to the program in every terminal, so there is
-- never a question of which terminal you are standing in.
--
-- Snacks forces that choice anyway. It binds <Esc> BUFFER-LOCALLY on its own
-- terminals as a 200ms double-tap, passing a single press through to the
-- program so Claude keeps it for interrupt, and buffer-local beats global.
-- A global <Esc> would therefore mean "leave" in a plain :terminal and
-- "interrupt" in Claude's pane. It means "interrupt" in both instead.
--
-- Three right-hand sides for one meaning: terminal mode needs <C-\><C-n>, the
-- command line needs <C-c> to abandon the line without running it, everything
-- else takes <Esc>. The RHS is never remapped, so <C-\> below does not swallow
-- the <C-\><C-n> here. Normal mode is included so the key is inert where you
-- are already there rather than falling through to something else.
--
-- <C-Space> echoes the Space leader and is unclaimed by vim, blink.cmp (preset
-- 'none'), oil, fugitive and telescope. Terminals send it as NUL, so it
-- survives terminal mode with no kitty keyboard protocol support.
vim.keymap.set('t', '<C-Space>', '<C-\\><C-n>', { desc = 'Go to Normal mode' })
vim.keymap.set({ 'n', 'i', 'v', 'o' }, '<C-Space>', '<Esc>', { desc = 'Go to Normal mode' })
vim.keymap.set('c', '<C-Space>', '<C-c>', { desc = 'Go to Normal mode' })

-- ================ Terminal in a Tab =====================
-- <C-\> is a legacy control byte (0x1C), so like <C-]>'s 0x1D it survives
-- terminal mode and Zellij with no kitty keyboard protocol support. Every mode,
-- like <C-]>, so it also reaches from inside Claude's pane and from another
-- shell.
--
-- A replacement, not an enhancement, and it costs two things. <C-\> is vim's
-- prefix for <C-\><C-n> and <C-\><C-o>; those are built-in sequences rather
-- than mappings, so a bare mapping wins outright with no timeoutlen stall --
-- but they become untypable, which is why <C-Space> above now carries
-- <C-\><C-n>'s job. And in terminal mode the byte no longer reaches the job,
-- so SIGQUIT to a wedged program in a pane needs `kill -QUIT` instead.
--
-- A tab, not a pane. Nothing here shares the screen with the editor, so this is
-- a plain :terminal rather than a Snacks one: it carries no b:snacks_terminal
-- and the one-pane-at-a-time rule in terminal.lua ignores it. <leader>tt is the
-- twin, bound to the same function.
local function terminal_tab()
  vim.cmd.tabnew()
  vim.cmd.terminal()
  vim.cmd.startinsert()
end

vim.keymap.set({ 'n', 'i', 'v', 'x', 't' }, '<C-\\>', terminal_tab, { desc = 'Terminal in a new tab' })
vim.keymap.set('n', '<leader>tt', terminal_tab, { desc = 'Terminal in a new tab' })

-- ================ Custom Commands =======================
vim.api.nvim_create_user_command('Projections', 'edit .projections.json', {})
