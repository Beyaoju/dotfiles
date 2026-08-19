return {
  {
    'catppuccin/nvim',
    lazy = false,
    priority = 1000,
    name = 'catppuccin',
    config = function()
      local uname = vim.uv.os_uname()
      local transparent = uname.sysname == 'Darwin'
        or string.find(uname.sysname, 'Windows') ~= nil
        or string.find(uname.release, 'WSL') ~= nil

      require('catppuccin').setup({
        flavour = 'mocha',
        transparent_background = transparent,
        no_italic = true,
        integrations = {
          snacks = {
            enabled = true,
          },
        },
      })

      vim.cmd('colorscheme catppuccin')

      -- Make the dimmed directory path in the Snacks picker readable
      local palette = require('catppuccin.palettes').get_palette('mocha')
      vim.api.nvim_set_hl(0, 'SnacksPickerDir', { fg = palette.overlay0 })
      vim.api.nvim_set_hl(0, 'DiagnosticUnderlineError', { undercurl = true, sp = palette.red })
      vim.api.nvim_set_hl(0, 'DiagnosticUnderlineWarn', { undercurl = true, sp = palette.yellow })
      vim.api.nvim_set_hl(0, 'DiagnosticUnderlineInfo', { undercurl = true, sp = palette.blue })
      vim.api.nvim_set_hl(0, 'DiagnosticUnderlineHint', { undercurl = true, sp = palette.teal })
    end,
  },
}
