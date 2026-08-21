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
local initial_cwd = vim.fn.getcwd()

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

-- ファイルタイプ自動判定 (シェルスクリプト)
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  pattern = { ".bash*", ".profile", "*.sh" },
  command = "set filetype=sh",
})

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
-- 共通 LSP 設定 (on_attach)
-- ====================
local on_attach = function(client, bufnr)
  local buf_map = function(mode, lhs, rhs)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr })
  end
  buf_map("n", "F", function()
    vim.lsp.buf.hover({
      max_width = 60,
      max_height = 15,
    })
  end)
  buf_map("n", "f", vim.diagnostic.open_float)

  -- 保存時フォーマット
  if client:supports_method("textDocument/formatting", bufnr) then
    vim.api.nvim_create_autocmd("BufWritePre", {
      buffer = bufnr,
      callback = function()
        if vim.bo.filetype == "python" then
          -- Ruffのインポート整理を実行
          vim.lsp.buf.code_action({
            context = { only = { "source.organizeImports" } },
            apply = true,
          })
          -- アクションの適用を待つためにわずかに待機
          vim.wait(100)
        end

        vim.lsp.buf.format({
          bufnr = bufnr,
          filter = function(c)
            if vim.bo.filetype == "python" then
              return c.name == "ruff"
            elseif vim.bo.filetype == "prisma" then
              return c.name == "prismals"
            else
              return c.name == "null-ls"
            end
          end,
        })
      end,
    })
  end
end

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
    "akinsho/toggleterm.nvim",
    version = "*",
    keys = {
      { "<C-\\>", "<cmd>ToggleTerm<cr>", mode = { "n", "t" }, desc = "Toggle Terminal" },
    },
    opts = {
      -- 見た目の設定
      direction = "float",
      float_opts = {
        border = "curved",
        winblend = 3,
      },
      size = 20,
      start_in_insert = true,
      hide_numbers = true,
      shade_terminals = true,
    },
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
    -- oil.nvim (テキスト編集感覚でファイル操作)
    "stevearc/oil.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      "refractalize/oil-git-status.nvim",
    },
    keys = {
      -- 現在の e キーでフローティング表示
      { "e", function() require("oil").toggle_float() end, desc = "Open oil.nvim in float" },
    },
    config = function()
      require("oil").setup({
        -- デフォルトのエクスプローラーにする（netrwを完全に置き換え）
        default_file_explorer = true,
        -- カラム設定（アイコン、パーミッション、サイズなど）
        columns = {
          "icon",
          -- "permissions",
          -- "size",
        },
        -- oil-git-status.nvim が git status を表示するために2列分の signcolumn を確保
        win_options = {
          signcolumn = "yes:2",
        },
        -- フローティングウィンドウの設定
        float = {
          padding = 2,
          max_width = math.floor(vim.o.columns * 0.5), -- 画面幅の50%
          max_height = math.floor(vim.o.lines * 0.7),  -- 画面高さの70%
          border = "rounded",
          win_options = {
            signcolumn = "yes:2",
            winblend = 0,
          },
        },
        -- 表示設定
        view_options = {
          -- ドットファイルを表示するかどうか
          show_hidden = false,
        },
        use_default_keymaps = false,
        keymaps = {
          ["<CR>"] = "actions.select",
          ["s"] = { "actions.select", opts = { vertical = true } },
          ["q"] = { "actions.close", mode = "n" },
          ["-"] = { "actions.parent", mode = "n" },
          ["."] = { "actions.toggle_hidden", mode = "n" },
        },
      })
      require("oil-git-status").setup({
        show_ignored = false,
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
        lualine_c = {
          {
            function()
              local filename = vim.api.nvim_buf_get_name(0)
              if filename == "" then
                return "[No Name]"
              end

              local relative = vim.fs.relpath(initial_cwd, filename)
              return relative or vim.fn.fnamemodify(filename, ":~")
            end,
          },
        },
        lualine_x = { "encoding", "fileformat", "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
    },
  },

  {
    -- Treesitter (Neovim 0.12 向け新版)
    "nvim-treesitter/nvim-treesitter",
    url = "https://github.com/neovim-treesitter/nvim-treesitter",
    dependencies = { "neovim-treesitter/treesitter-parser-registry" },
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local treesitter = require("nvim-treesitter")
      treesitter.setup()

      local languages = {
        "bash",
        "lua",
        "python",
        "typescript",
        "vue",
        "javascript",
        "json",
        "html",
        "html_tags",
        "css",
        "ecma",
        "jsx",
        "tsx",
        "markdown",
        "markdown_inline",
        "prisma",
      }

      local installed = {}
      for _, lang in ipairs(treesitter.get_installed()) do
        installed[lang] = true
      end
      local missing = vim.tbl_filter(function(lang)
        return not installed[lang]
      end, languages)
      if #missing > 0 then
        treesitter.install(missing)
      end

      vim.api.nvim_create_autocmd("FileType", {
        pattern = {
          "sh",
          "bash",
          "lua",
          "python",
          "typescript",
          "typescriptreact",
          "vue",
          "javascript",
          "javascriptreact",
          "json",
          "html",
          "css",
          "markdown",
          "prisma",
        },
        callback = function()
          pcall(vim.treesitter.start)
        end,
      })
    end,
  },

  {
    -- LSP設定
    "neovim/nvim-lspconfig",
    config = function()
      -- Diagnostic 表示設定
      vim.diagnostic.config({
        virtual_text = false,
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
      })

      -- Pyright
      vim.lsp.config("pyright", {
        on_attach = on_attach,
        filetypes = { "python" },
        root_markers = { ".venv" },
        settings = {
          python = {
            analysis = {
              -- 型チェックはPyright、診断はRuffに任せるための設定
              typeCheckingMode = "basic",
            }
          }
        }
      })
      vim.lsp.enable("pyright")

      -- Ruff (Linter & Formatter)
      vim.lsp.config("ruff", {
        on_attach = on_attach,
      })
      vim.lsp.enable("ruff")

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
      local function get_vue_plugin_path()
        local bun_install = os.getenv("BUN_INSTALL")
        if bun_install then
          return bun_install .. "/install/global/node_modules/@vue/typescript-plugin/"
        end
        return ""
      end

      local vue_plugin = {
        name = "@vue/typescript-plugin",
        location = get_vue_plugin_path(),
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

      -- Prisma
      vim.lsp.config("prismals", {
        on_attach = on_attach,
        filetypes = { "prisma" },
        root_markers = {
          "package.json",
          ".git",
        },
      })
      vim.lsp.enable("prismals")
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

      null_ls.setup({
        sources = {
          -- Shell
          null_ls.builtins.formatting.shfmt,
          -- TypeScript / JSON / etc.
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
        on_attach = on_attach,
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
