" -------------------------------------------------------
" Plugin
" -------------------------------------------------------
call plug#begin('~/.vim/plugged')
Plug 'pineapplegiant/spaceduck', { 'branch': 'main' } " テーマ
Plug 'itchyny/lightline.vim' " 下部のステータスライン
Plug 'lukas-reineke/indent-blankline.nvim' " インデントライン
Plug 'mechatroner/rainbow_csv' " CSVをレインボーにする
Plug 'tpope/vim-commentary' " gccでコメントアウトできる
Plug 'justinmk/vim-sneak' " s + 二文字で検索
Plug 'airblade/vim-gitgutter' " Git ステータス
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'ervandew/supertab' " タブで補完を選択
Plug 'mzlogin/vim-markdown-toc' " マークダウンの目次生成
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'} " ハイライト
Plug 'yioneko/nvim-yati' " インデント
Plug 'norcalli/nvim-colorizer.lua'
Plug 'akinsho/toggleterm.nvim', {'tag': 'v1.*'} " terminal
Plug 'mracos/mermaid.vim'
Plug 'previm/previm'
call plug#end()


" -------------------------------------------------------
" coc
" -------------------------------------------------------
let g:coc_disable_startup_warning = 1
let g:coc_global_extensions = [
  \ 'coc-jedi',
  \ 'coc-yaml',
  \ 'coc-html',
  \ 'coc-json',
  \ 'coc-lua',
  \ 'coc-tsserver',
\ ]
nmap <silent> e <Cmd>CocCommand explorer<CR>


" -------------------------------------------------------
" super tab
" -------------------------------------------------------
let g:SuperTabDefaultCompletionType = "<c-n>" " タブで補完を選択するときに下向きに選択していく


" -------------------------------------------------------
" sneak search
" -------------------------------------------------------
let g:sneak#label = 1


" -------------------------------------------------------
" indent line
" -------------------------------------------------------
let g:indentLine_conceallevel = 0 " Markdownで強調表示が消えるのを防ぐ


" -------------------------------------------------------
" toggle term
" -------------------------------------------------------
autocmd TermEnter term://*toggleterm#*
\ tnoremap <silent><c-\> <Cmd>exe v:count1 . "ToggleTerm"<CR>
nnoremap <silent><c-\> <Cmd>exe v:count1 . "ToggleTerm"<CR>


" -------------------------------------------------------
" previm
" -------------------------------------------------------
let g:previm_open_cmd = '/mnt/c/Program\ Files\ \(x86\)/Microsoft/Edge/Application/msedge.exe --inprivate'
let g:previm_wsl_mode = 1
let g:previm_disable_default_css = 1
let g:previm_custom_css_path = '~/public/css/github.css'
let g:previm_enable_realtime = 1
let g:previm_show_header = 0
nmap <silent> - <Cmd>PrevimOpen<CR>


" -------------------------------------------------------
" general
" -------------------------------------------------------
set conceallevel=0
autocmd BufNewFile,BufRead *.tsx,*.jsx set filetype=typescriptreact " set filetypes as typescriptreact
set termguicolors


" -------------------------------------------------------
" Lua settings
" -------------------------------------------------------
lua << EOF
require('nvim-treesitter.configs').setup{
  highlight = { enable = true },
  yati = { enable = true }
}
require('colorizer').setup()
require("indent_blankline").setup {
  show_current_context_start = true,
  show_end_of_line = true
}
require("toggleterm").setup{
  direction = 'float'
}
EOF


" -------------------------------------------------------
" general
" -------------------------------------------------------
set enc=utf-8
set fenc=utf-8
set fileformats=unix,dos,mac
set nobackup " バックアップを作らない
set noswapfile " スワップファイルを作らない
set autoread " ファイルに変更があった場合自動で読み込みなおす
set hidden " 保存されていないファイルがあるときでも別のファイルを開ける
set cindent " 賢いインデントモード (polyglotのオートインデントが使われるので無効)
set virtualedit=onemore " 行末の文字の一つ先までカーソルを置ける
set mouse=a " マウスホイールでスクロールが出来るようになる
set wildmode=list:longest " ファイル名を入力する際にタブ補完
set wildmenu " コマンド入力補完
set backspace=indent,eol,start " backspaceでインデント・行末・行頭を削除できる
set ttyfast " スクロール時に再描画を行う
set expandtab " インデントの際にタブ文字ではなくスペースが挿入される
set tabstop=2 " タブのスペース挿入数
set shiftwidth=2 " タブのスペース挿入数
set showcmd " 入力中のコマンドを右下に表示する
set title " ターミナルのウィンドウのタブにファイル名を表示する
set number " 行番号の表示
set textwidth=0 " 自動改行オフ
set laststatus=2
set noshowmode "モードを変えたときに左下にでる文字を無効化する
set nowrap " 行を画面の終端で折り返さない
set cmdheight=1
set cursorline "カーソルライン


" -------------------------------------------------------
" keymapping
" -------------------------------------------------------
let mapleader = "\<Space>"
nmap j gj
nmap k gk
nmap n nzz
nmap N Nzz
nmap <C-h> <C-w>h
nmap <C-j> <C-w>j
nmap <C-k> <C-w>k
nmap <C-l> <C-w>l
nmap <silent> <Leader><Leader> :let @/ = '\<' . expand('<cword>') . '\>'<CR>:set hlsearch<CR>
nmap p ]p
nmap P ]P
nmap Y y$
nmap J 10j
nmap K 10k
nmap G Gzz
nmap U <C-r>
nmap H I<Esc>
nmap L $
nmap <C-o> mzo<Esc>`z
nmap <C-S-o> mzO<Esc>`z
nmap <silent> <F3> <ESC>i<C-R>=strftime("%Y/%m/%d")<CR><CR><ESC>
nmap <silent> <Esc><Esc> :nohlsearch<CR><Esc>
nmap # <Leader><Leader>:%s/<C-r>///g<Left><Left>
vmap < <gv
vmap > >gv
imap <silent> jj <Esc>
imap <silent> <F3> <C-R>=strftime("%Y/%m/%d")<CR>


" -------------------------------------------------------
" Search option
" -------------------------------------------------------
set ignorecase
set smartcase
set incsearch
set wrapscan
set hlsearch


" -------------------------------------------------------
" Theme
" -------------------------------------------------------
" カーソルの形
let &t_SI.="\e[6 q"
let &t_EI.="\e[2 q"
let &t_SR.="\e[4 q"
syntax enable
" Spaceduck
autocmd ColorScheme * highlight Comment ctermfg=60 guifg=#5f5f87
colorscheme spaceduck
let g:lightline = { 'colorscheme': 'spaceduck' }

filetype plugin indent on


" -------------------------------------------------------
" Indent
" -------------------------------------------------------
autocmd FileType python setlocal sw=4 sts=4 ts=4 et
autocmd FileType markdown setlocal sw=4 sts=4 ts=4 et


