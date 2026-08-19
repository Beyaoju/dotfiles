local hide_tests = true

return {
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    opts = {
      picker = {
        enabled = true,
        sources = {
          explorer = {
            hidden = true,
            ignored = true,
            layout = {
              layout = {
                position = 'right',
              },
            },
          },
        },
      },
      explorer = { enabled = true },
      notifier = { enabled = true },
      input = { enabled = true },
      styles = {
        terminal = {
          keys = {
            term_normal = {
              '<C-Space>',
              function() vim.cmd.stopinsert() end,
              mode = 't',
              expr = false,
              desc = 'Exit Terminal Mode',
            },
          },
        },
      },
    },
    keys = {
      { '<leader>e', function() Snacks.explorer() end, desc = 'File Explorer' },
      { '<leader>f', function() Snacks.picker.files() end, desc = 'Find Files' },
      { '<leader>s', function() Snacks.picker.grep() end,  desc = 'Search Text' },
      { '<leader>b', function() Snacks.picker.buffers() end, desc = 'Buffers' },
      { '<leader>t', function() Snacks.terminal() end, desc = 'Terminal' },
      { 'gd', function() Snacks.picker.lsp_definitions() end, desc = 'Goto Definition' },
      { 'gr', function()
        Snacks.picker.lsp_references({
          transform = function(item)
            if not hide_tests then return true end
            return not (item.file:match('%.test%.') or item.file:match('%.spec%.'))
          end,
        })
      end, desc = 'Goto References' },
      { '<leader>gt', function()
        hide_tests = not hide_tests
        vim.notify('gr: test/spec files ' .. (hide_tests and 'hidden' or 'shown'))
      end, desc = 'Toggle test files in References' },
    },
  },
}
