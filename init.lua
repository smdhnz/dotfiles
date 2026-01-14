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
    "nvim-tree/nvim-tree.lua",
    version = "*",
    lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "e", "<CMD>NvimTreeToggle<CR>", silent = true, noremap = true },
    },
    config = function()
      -- ==========================================
      -- 1. 無視ファイルリスト
      -- ==========================================
      local custom_ignore_list = {
        "node_modules",
        ".git",
        ".nuxt",
        ".output",
        "__pycache__",
        ".venv",
        ".gemini"
      }

      -- ==========================================
      -- 2. ハイライト自動適用 (BufWinEnterを追加)
      -- ==========================================
      vim.api.nvim_create_autocmd({ "BufWinEnter", "FileType" }, {
        pattern = "*",
        callback = function()
          if vim.bo.filetype ~= "NvimTree" then
            return
          end

          -- 描画タイミングのズレを防ぐために schedule でラップ
          vim.schedule(function()
            -- 念のため既存の match をクリア（重複防止）
            vim.fn.clearmatches()

            -- A. ドットファイル (.config など) をグレーアウト
            vim.fn.matchadd("Comment", [[ \zs\.[^ ]\+]])

            -- B. custom_ignore_list を正規表現に変換してグレーアウト
            local escaped_list = {}
            for _, name in ipairs(custom_ignore_list) do
              table.insert(escaped_list, vim.fn.escape(name, "."))
            end
            local pattern = table.concat(escaped_list, "\\|")

            if pattern ~= "" then
              -- 正規表現: スペースの後にリスト内の単語があり、その直後が行末かスペース
              vim.fn.matchadd("Comment", [[ \zs\(]] .. pattern .. [[\)\ze\($\| \)]])
            end
          end)
        end,
      })

      -- ==========================================
      -- 3. カスタムキーマップ
      -- ==========================================
      local function my_on_attach(bufnr)
        local api = require("nvim-tree.api")
        local function opts(desc)
          return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
        end

        local function toggle_all_filters()
          api.tree.toggle_hidden_filter()
          api.tree.toggle_custom_filter()
          api.tree.toggle_gitignore_filter()
        end

        vim.keymap.set("n", "<CR>", api.node.open.edit,           opts("Open"))
        vim.keymap.set("n", "e",    api.tree.close,               opts("Close"))
        vim.keymap.set("n", ".",    toggle_all_filters,           opts("Toggle All Filters"))
        vim.keymap.set("n", "q",    api.tree.close,               opts("Close"))
        vim.keymap.set("n", "s",    api.node.open.vertical,       opts("Open: Vertical Split"))
        vim.keymap.set("n", "u",    api.tree.change_root_to_parent, opts("Up"))
        vim.keymap.set("n", "o",    api.tree.change_root_to_node,   opts("CD"))
        vim.keymap.set("n", "a",    api.fs.create,                opts("Create"))
        vim.keymap.set("n", "d",    api.fs.remove,                opts("Delete"))
        vim.keymap.set("n", "r",    api.fs.rename,                opts("Rename"))
        vim.keymap.set("n", "x",    api.fs.cut,                   opts("Cut"))
        vim.keymap.set("n", "c",    api.fs.copy.node,             opts("Copy"))
        vim.keymap.set("n", "p",    api.fs.paste,                 opts("Paste"))
      end

      -- ==========================================
      -- 4. 本体設定
      -- ==========================================
      require("nvim-tree").setup({
        on_attach = my_on_attach,
        update_focused_file = { enable = true },
        view = {
          float = {
            enable = true,
            quit_on_focus_loss = true,
            open_win_config = function()
              local screen_w = vim.opt.columns:get()
              local screen_h = vim.opt.lines:get() - vim.opt.cmdheight:get()
              local window_w = math.floor(screen_w * 0.4)
              local window_h = math.floor(screen_h * 0.8)
              local center_x = (screen_w - window_w) / 2
              local center_y = ((vim.opt.lines:get() - window_h) / 2) - vim.opt.cmdheight:get()
              return {
                relative = "editor",
                border = "rounded",
                width = window_w,
                height = window_h,
                row = center_y,
                col = center_x,
              }
            end,
          },
        },
        renderer = {
          special_files = {},
          highlight_git = true,
          indent_markers = { enable = true },
          icons = {
            glyphs = {
              git = {
                unstaged  = "",
                staged    = "",
                unmerged  = "",
                renamed   = "󰑖",
                untracked = "",
                deleted   = "",
                ignored   = "",
              },
            },
          },
        },
        filters = {
          dotfiles = true,
          custom = custom_ignore_list,
        },
        actions = {
          open_file = {
            quit_on_open = true,
            window_picker = { enable = false },
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
