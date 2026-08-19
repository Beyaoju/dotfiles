  return {
    {
      'mason-org/mason.nvim',
      opts = {},
    },
    {
      'neovim/nvim-lspconfig',
      dependencies = { 'mason-org/mason.nvim' },
    },
    {
      'mason-org/mason-lspconfig.nvim',
      dependencies = {
        'mason-org/mason.nvim',
        'neovim/nvim-lspconfig',
      },
      opts = {
        ensure_installed = {
          'vtsls',
          'eslint',
          'gopls',
          'tailwindcss',
          'prismals',
          'yamlls',
          'docker_language_server',
          'bashls',
          'jsonls',
          'cssls',
          'html',
        },
        automatic_enable = true,
      },
    },
  }
