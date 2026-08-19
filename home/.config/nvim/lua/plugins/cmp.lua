return {
  {
    'saghen/blink.cmp',
    version = '*',
    opts = {
      keymap = {
        preset = 'default',
        ['<CR>'] = { 'accept', 'fallback' },
      },
      appearance = { nerd_font_variant = 'mono' },
      sources = { default = { 'lsp', 'path', 'buffer', 'snippets' } },
      completion = { documentation = { auto_show = true } },
    },
  },
}
