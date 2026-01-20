-- ====================
-- 高速化: バイトコードキャッシュ有効化
-- ====================
if vim.loader then
  vim.loader.enable()
end

-- ====================
-- Leader キーの設定
-- ====================
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- ====================
-- Neovim オプション
-- ====================
local g = vim.g
local opt = vim.opt

-- 表示関連
opt.number = true
opt.relativenumber = false
opt.list = true
opt.showmode = false
opt.showtabline = 0
vim.o.signcolumn = "yes"
opt.cmdheight = 0
opt.laststatus = 3

-- 検索関連
opt.smartcase = true
opt.hlsearch = true
opt.ignorecase = true
opt.incsearch = true

-- インデント関連
opt.autoindent = true
opt.smartindent = false
opt.expandtab = true
opt.smarttab = false
opt.shiftwidth = 2
opt.tabstop = 2

-- 見た目関連
opt.termguicolors = true
opt.wrap = false
opt.fillchars = { eob = " " }
opt.scrolloff = 10
opt.sidescrolloff = 10
opt.conceallevel = 0

-- ファイル関連
opt.swapfile = false
opt.undofile = true
opt.lazyredraw = true
opt.autowrite = true
opt.splitkeep = "screen"

-- タイムアウト関連
opt.timeout = true
opt.timeoutlen = 500

-- その他
opt.splitbelow = true
opt.mouse = "a"
opt.foldenable = false
opt.grepprg = "rg --vimgrep"
opt.grepformat = "%f:%l:%c:%m"
opt.shortmess:append({ W = true, I = true, c = true, C = true })
opt.confirm = true
opt.completeopt = "menu,menuone,noselect,noinsert"

-- 不要なプラグイン無効化
g.loaded_netrw = 1
g.loaded_netrwPlugin = 1
g.loaded_gzip = 1
g.loaded_zip = 1
g.loaded_tar = 1
g.loaded_vimball = 1
g.loaded_2html_plugin = 1
g.loaded_logipat = 1
g.loaded_getscript = 1
g.loaded_getscriptPlugin = 1
g.loaded_tutor_mode_plugin = 1
g.loaded_node_provider = 0
g.loaded_perl_provider = 0
g.loaded_python3_provider = 0
g.matchup_matchparen_offscreen = { method = "status_manual " }

-- ====================
-- キーマップ定義
-- ====================
local map = vim.api.nvim_set_keymap

-- カーソル移動
map("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
map("x", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map("x", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
map("n", "J", "10j", { silent = true })
map("n", "K", "10k", { silent = true })
map("n", "G", "Gzz", { silent = true })

-- ウィンドウ移動
map("n", "<C-h>", "<C-w>h", { noremap = true, silent = true })
map("n", "<C-j>", "<C-w>j", { noremap = true, silent = true })
map("n", "<C-k>", "<C-w>k", { noremap = true, silent = true })
map("n", "<C-l>", "<C-w>l", { noremap = true, silent = true })

-- 検索
map("n", "<esc><esc>", "<cmd>nohlsearch<cr>", { silent = true })
map("n", "<leader><leader>", "<CMD>let @/ = '\\<' . expand('<cword>') . '\\>'<CR><CMD>set hlsearch<CR>", { silent = true })
map("n", "n", "nzz", { silent = true })
map("n", "N", "Nzz", { silent = true })

-- 貼り付け・やり直し
map("n", "p", "]p", { silent = true })
map("n", "P", "]P", { silent = true })
map("n", "U", "<C-r>", { silent = true })

-- 行移動
map("n", "H", "^", { silent = true })
map("x", "H", "^", { silent = true })
map("n", "L", "$", { silent = true })
map("x", "L", "$", { silent = true })

-- 日付挿入
map("n", "<F3>", '<ESC>i<C-R>=strftime("%Y/%m/%d")<CR><CR><ESC>', { silent = true })
map("i", "<F3>", '<C-R>=strftime("%Y/%m/%d")<CR>', { silent = true })

-- :s を %s///g に変換
vim.cmd([[cnoreabbrev <expr> s getcmdtype() .. getcmdline() ==# ":s" ? "%s///g<Left><Left>" : "s"]])

-- ====================
-- Lazy.nvim 初期化
-- ====================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ====================
-- プラグイン設定
-- ====================
require("lazy").setup({
  {
    -- コメントトグル
    "numToStr/Comment.nvim",
    opts = {},
  },

  {
    -- Telescope (ファジー検索)
    'nvim-telescope/telescope.nvim',
    branch = "0.1.x",
    dependencies = {
      'nvim-lua/plenary.nvim',
      { 'nvim-telescope/telescope-fzf-native.nvim', build = "make" }
    },
    cmd = { "Telescope" },
    keys = {
      { "<C-f>", "<CMD>Telescope live_grep<CR>", silent = true, noremap = true },
    },
    config = function()
      require("telescope").setup({
        defaults = {
          file_ignore_patterns = { "^.git/", "^.venv/", "^node_modules/" },
          vimgrep_arguments = {
            "rg", "--color=never", "--no-heading", "--with-filename",
            "--line-number", "--column", "--smart-case", "-uu",
          },
        },
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          },
        },
      })
      require("telescope").load_extension("fzf")
    end,
  },

  {
    -- LazyGit
    "kdheepak/lazygit.nvim",
    lazy = true,
    keys = {
      { "q", "<CMD>LazyGit<CR>", silent = true, noremap = true },
    },
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      vim.g.lazygit_floating_window_scaling_factor = 1
      vim.g.lazygit_floating_window_border_chars = { "", "", "", "", "", "", "", "" }
    end,
  },

  {
    -- Hop (高速移動)
    "phaazon/hop.nvim",
    branch = "v2",
    keys = {
      { "s", "<CMD>HopWord<CR>", silent = true, noremap = true },
    },
    opts = { keys = "etovxqpdygfblzhckisuran" },
  },

  {
    -- テーマ: TokyoNight
    "folke/tokyonight.nvim",
    priority = 1000,
    config = function()
      require("tokyonight").setup({
        styles = {
          comments = { italic = false },
          keywords = { italic = false },
        },
        hide_inactive_statusline = true,
        dim_inactive = false,
        lualine_bold = true,
      })
      vim.cmd([[colorscheme tokyonight-night]])
    end,
  },

  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    keys = {
      -- e キーで起動
      { "e", "<CMD>Neotree toggle<CR>", desc = "Toggle Neo-tree" },
    },
    config = function()
      require("neo-tree").setup({
        close_if_last_window = true,
        -- デフォルトのマッピングをなるべく排除するための設定
        use_default_mappings = false, 

        window = {
          position = "float",
          popup = {
            size = { height = "80%", width = "50%" },
            position = "50%", -- 画面中央
            border = "rounded",
          },
          mappings = {
            ["u"] = "navigate_up", -- 親ディレクトリに移動 (Go up)
            ["o"] = "set_root", -- ディレクトリの中へ移動 (Set root / Go into)
            ["<CR>"] = "open", -- ファイルなら開く、フォルダなら開閉 (Toggle/Open)
            ["s"] = "open_vsplit", -- 縦スプリットで開く
            ["d"] = "delete", -- 削除
            ["n"] = "add", -- 新規作成 (ファイル・フォルダ)
            ["y"] = "copy_to_clipboard", -- コピー
            ["p"] = "paste_from_clipboard", -- ペースト
            ["q"] = "close_window", -- 閉じる
            ["?"] = "show_help", -- ヘルプ表示 (マッピングを忘れたとき用)
            ["."] = "toggle_hidden", --  隠しファイル・Ignoreファイルの表示切り替え

            -- 無効化
            ["<space>"] = "none",
            ["/"] = "none",
            ["z"] = "none",
          },
        },
        filesystem = {
          follow_current_file = { enabled = false },
          bind_to_cwd = false,
          use_libuv_file_watcher = true,
          -- 隠しファイルとフィルタリングの設定
          filtered_items = {
            -- visible = false: フィルタリングを有効にする（デフォルトで隠す）
            visible = false,
            -- ドットファイル（.configなど）を隠す
            hide_dotfiles = true,
            -- .gitignore に書かれているファイルを隠す
            hide_gitignored = true,
            -- 名前指定で隠す（ここに node_modules などを追加）
            hide_by_name = {
              "node_modules",
            },
            -- ワイルドカードで隠したい場合（例: *.meta ファイルなど）
            -- hide_by_pattern = { 
            --   "*.meta", 
            -- },
          },
        },
      })
    end,
  },

  {
    -- Git インジケーター
    "lewis6991/gitsigns.nvim",
    opts = {
      signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
      },
      signcolumn = true,
      numhl = true,
      linehl = true,
    },
  },

  {
    -- ステータスライン
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "VeryLazy",
    opts = {
      options = {
        icons_enabled = true,
        theme = "auto",
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = { { "filename", path = 1 } },
        lualine_x = { "encoding", "fileformat", "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
    },
  },

  {
    -- Treesitter
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    dependencies = { "yioneko/nvim-yati" },
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        highlight = { enable = true },
        autotag = { enable = true },
        indent = { enable = false },
        yati = { enable = true },
      })
    end,
  },

  {
    -- LSP設定
    "neovim/nvim-lspconfig",
    config = function()
      -- hoverの設定
      vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
        vim.lsp.handlers.hover,
        {
          max_width = 60,
          max_height = 15,
        }
      )

      -- Diagnostic 表示設定
      vim.diagnostic.config({
        virtual_text = false,
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
      })

      -- 共通on_attach（フォーマット等）
      local on_attach = function(client, bufnr)
        local buf_map = function(mode, lhs, rhs)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr })
        end
        buf_map("n", "F", vim.lsp.buf.hover)
        buf_map("n", "f", vim.diagnostic.open_float)
      end

      -- Pyright
      vim.lsp.config("pyright", {
        on_attach = on_attach,
        filetypes = { "python" },
        root_markers = { ".venv" },
      })
      vim.lsp.enable("pyright")

      -- Tailwind CSS
      vim.lsp.config("tailwindcss", {
        on_attach = on_attach,
        filetypes = {
          "typescriptreact",
          "vue",
          "html",
          "css",
        },
        root_markers = { 'tailwind.config.js', 'postcss.config.js' },
      })
      vim.lsp.enable("tailwindcss")

      -- Typescript & Vue
      local vue_language_server_path = os.getenv("HOME")
        .. "/.volta/tools/shared/@vue/language-server/node_modules/@vue/typescript-plugin"
      local vue_plugin = {
        name = "@vue/typescript-plugin",
        location = vue_language_server_path,
        languages = { "vue" },
        configNamespace = "typescript",
      }
      vim.lsp.config("vtsls", {
        on_attach = on_attach,
        root_markers = { "package.json", "tsconfig.json" },
        workspace_required = true,
        settings = {
          vtsls = {
            tsserver = {
              globalPlugins = {
                vue_plugin,
              },
            },
          },
        },
        filetypes = {
          "typescript",
          "typescriptreact",
          "vue",
        },
      })
      vim.lsp.enable("vtsls")
    end
  },

  {
    'saghen/blink.cmp',
    version = '1.*',
    opts = {
      keymap = {
        preset = 'enter',
        ['<S-TAB>'] = { 'select_prev', 'fallback' },
        ['<TAB>'] = { 'select_next', 'fallback' },
      },
      completion = {
        documentation = { auto_show = true },
        list = { selection = { preselect = false, auto_insert = true } },
      },
      sources = { default = { 'lsp', 'path', 'snippets', 'buffer' } },
      fuzzy = { implementation = "prefer_rust_with_warning" },
    },
    opts_extend = { "sources.default" },
  },

  {
    -- none-ls: フォーマッタ/リンタ統合
    "nvimtools/none-ls.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local null_ls = require("null-ls")

      local lsp_format_on_save = function(bufnr)
        vim.api.nvim_create_autocmd("BufWritePre", {
          buffer = bufnr,
          callback = function()
            vim.lsp.buf.format({
              async = false,
              filter = function(client)
                return client.name == "null-ls"
              end,
            })
          end,
        })
      end

      null_ls.setup({
        sources = {
          -- Python
          null_ls.builtins.formatting.black,
          null_ls.builtins.formatting.isort,
          -- TypeScript
          null_ls.builtins.formatting.prettierd.with({
            filetypes = {
              "typescript",
              "typescriptreact",
              "vue",
              "json",
              "yaml",
              "css",
              "html",
              "markdown",
            }
          }),
        },
        on_attach = function(client, bufnr)
          if client.name == "null-ls" then
            lsp_format_on_save(bufnr)
          end
        end,
      })
    end,
  },

  -- ====================
  -- Lazy.nvim 自体のチューニング
  -- ====================
  defaults = {
    lazy = true,
  },
  performance = {
    cache = {
      enabled = true,
    },
    rtp = {
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
