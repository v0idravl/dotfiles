-- ── Options ────────────────────────────────────────────────────
vim.opt.number         = true
vim.opt.relativenumber = true
vim.opt.cursorline     = true
vim.opt.showcmd        = true
vim.opt.wildmenu       = true
vim.opt.scrolloff      = 5
vim.opt.colorcolumn    = '80'

vim.opt.tabstop        = 4
vim.opt.shiftwidth     = 4
vim.opt.expandtab      = true
vim.opt.smartindent    = true
vim.opt.autoindent     = true

vim.opt.ignorecase     = true
vim.opt.smartcase      = true
vim.opt.incsearch      = true
vim.opt.hlsearch       = true

vim.opt.wrap           = false
vim.opt.backspace      = 'indent,eol,start'
vim.opt.clipboard      = 'unnamedplus'
vim.opt.mouse          = 'a'

vim.opt.hidden         = true
vim.opt.backup         = false
vim.opt.writebackup    = false
vim.opt.updatetime     = 300
vim.opt.undofile       = true
vim.opt.undodir        = vim.fn.expand('~/.vim/undodir')

vim.opt.laststatus     = 2
vim.opt.termguicolors  = true

-- ── Keymaps ────────────────────────────────────────────────────
vim.g.mapleader = ' '

vim.keymap.set('n', '<leader>w',  ':w<CR>')
vim.keymap.set('n', '<leader>q',  ':q<CR>')
vim.keymap.set('n', '<leader>/',  ':nohlsearch<CR>')
vim.keymap.set('i', 'jk',         '<Esc>')

-- Telescope
vim.keymap.set('n', '<leader>ff', '<cmd>Telescope find_files<CR>')
vim.keymap.set('n', '<leader>fg', '<cmd>Telescope live_grep<CR>')
vim.keymap.set('n', '<leader>fb', '<cmd>Telescope buffers<CR>')
vim.keymap.set('n', '<leader>fr', '<cmd>Telescope oldfiles<CR>')

-- LSP
vim.keymap.set('n', 'gd',         vim.lsp.buf.definition)
vim.keymap.set('n', 'K',          vim.lsp.buf.hover)
vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename)
vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action)
vim.keymap.set('n', '[d',         vim.diagnostic.goto_prev)
vim.keymap.set('n', ']d',         vim.diagnostic.goto_next)

-- ── lazy.nvim bootstrap ────────────────────────────────────────
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({ 'git', 'clone', '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git', '--branch=stable', lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- ── Plugins ────────────────────────────────────────────────────
require('lazy').setup({

  -- colorscheme — kanagawa dragon, retinted red/orange for the kali "evil twin"
  {
    'rebelot/kanagawa.nvim',
    lazy     = false,
    priority = 1000,
    opts = {
      theme = 'dragon',
      overrides = function(colors)
        local p     = colors.palette
        local theme = colors.theme
        return {
          Keyword      = { fg = p.autumnRed, bold = true },
          Statement    = { fg = p.autumnRed },
          Conditional  = { fg = p.autumnRed },
          Repeat       = { fg = p.autumnRed },
          Operator     = { fg = p.peachRed },
          Function     = { fg = p.surimiOrange },
          CursorLineNr = { fg = p.samuraiRed, bold = true },
          Visual       = { bg = p.winterRed },
          ColorColumn  = { bg = p.winterRed },
          StatusLine   = { fg = p.roninYellow, bg = theme.ui.bg_p1 },
        }
      end,
    },
  },

  -- fuzzy finder
  {
    'nvim-telescope/telescope.nvim', tag = '0.1.8',
    dependencies = { 'nvim-lua/plenary.nvim' },
  },

  -- treesitter parser manager — main branch (master is frozen and crashes on nvim 0.12)
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy   = false,
    build  = ':TSUpdate',
    config = function()
      require('nvim-treesitter').install({ 'python', 'c', 'lua', 'markdown', 'bash', 'vim', 'asm' })
      -- main branch does not auto-start highlighting; per-buffer opt-in
      vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'python', 'c', 'lua', 'markdown', 'bash', 'sh', 'vim', 'asm' },
        callback = function()
          pcall(vim.treesitter.start)
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },

  -- LSP server UI (:Mason) — install servers interactively
  { 'williamboman/mason.nvim', config = true },

  -- keybinding popup — pause after <leader> to see available keys
  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    config = function()
      local wk = require('which-key')
      wk.setup({ delay = 500 })
      wk.add({
        { '<leader>f', group = 'find' },
        { '<leader>ff', desc = 'files' },
        { '<leader>fg', desc = 'grep' },
        { '<leader>fb', desc = 'buffers' },
        { '<leader>fr', desc = 'recent' },
        { '<leader>w',  desc = 'write' },
        { '<leader>q',  desc = 'quit' },
        { '<leader>/',  desc = 'clear search' },
        { '<leader>rn', desc = 'lsp rename' },
        { '<leader>ca', desc = 'lsp code action' },
      })
    end,
  },

  -- completion
  {
    'hrsh7th/nvim-cmp',
    lazy         = false,
    dependencies = {
      { 'hrsh7th/cmp-nvim-lsp', lazy = false },
      'hrsh7th/cmp-buffer',
    },
    config = function()
      local cmp  = require('cmp')
      local caps = require('cmp_nvim_lsp').default_capabilities()

      vim.lsp.config.pylsp = {
        cmd          = { 'pylsp' },
        filetypes    = { 'python' },
        root_markers = { 'pyproject.toml', 'setup.py', 'requirements.txt', '.git' },
        capabilities = caps,
      }
      vim.lsp.enable('pylsp')

      vim.lsp.config.clangd = {
        cmd          = { 'clangd', '--background-index' },
        filetypes    = { 'c', 'cpp', 'h' },
        root_markers = { 'compile_commands.json', 'Makefile', '.git' },
        capabilities = caps,
      }
      vim.lsp.enable('clangd')

      cmp.setup({
        completion = { autocomplete = false }, -- manual only: <C-Space>
        mapping = cmp.mapping.preset.insert({
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<CR>']      = cmp.mapping.confirm({ select = true }),
          ['<Tab>']     = cmp.mapping.select_next_item(),
          ['<S-Tab>']   = cmp.mapping.select_prev_item(),
        }),
        sources = {
          { name = 'nvim_lsp' },
          { name = 'buffer' },
        },
      })
    end,
  },

}, {})

vim.cmd.colorscheme('kanagawa-dragon')
