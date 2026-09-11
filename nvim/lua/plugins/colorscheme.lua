return {
  {
    "projekt0n/github-nvim-theme",
    branch = "main",
    priority = 1000,
    config = function()
      -- github_dark_high_contrast gives Identifier, Tag, Special and Delimiter
      -- the same #F0F3F6 as Normal. Anything linked to them is therefore
      -- invisible -- which is every commit hash in every git buffer, since both
      -- syntax/git.vim and fugitive link their hash groups to Identifier.
      --
      -- Registered before the colorscheme loads so the `colorscheme` command
      -- below fires it, and re-fired on any later switch because `syntax reset`
      -- drops these.
      local function patch_git_highlights()
        local hl = function(group, link) vim.api.nvim_set_hl(0, group, { link = link }) end

        -- Hashes: git's own CLI prints these yellow, and Type is this theme's
        -- amber. Plain `hi link`, not `hi def link`, so the runtime syntax
        -- file's `def` mapping back to Identifier no longer takes.
        hl("gitHash", "Type")
        hl("gitOnelineHash", "Type")
        hl("fugitiveHash", "Type")
        hl("gitEmail", "Number")
        -- Tag collides with Normal the same way Identifier does; this is the
        -- keybinding hint in the status buffer's help header.
        hl("fugitiveHelpTag", "Constant")

        -- Ref decorations, following git's own palette: HEAD cyan, local
        -- branches green, remotes red, tags yellow, punctuation muted.
        hl("gitGraphGlyph", "Comment")
        hl("gitRefDelim", "Comment")
        hl("gitRefArrow", "Comment")
        hl("gitRefHead", "Constant")
        hl("gitRefLocal", "DiagnosticOk")
        hl("gitRefRemote", "Keyword")
        hl("gitRefTag", "Type")
      end

      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("GitHighlightPatch", { clear = true }),
        callback = patch_git_highlights,
      })

      vim.cmd("colorscheme github_dark_high_contrast")
    end,
  }
}
