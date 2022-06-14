" -------------------------------------------------------
" プラグイン
" -------------------------------------------------------
call plug#begin('~/.vim/plugged')
" ファイルツリー
Plug 'scrooloose/nerdtree',{'on':'NERDTreeToggle'}
" 見た目系
Plug 'pineapplegiant/spaceduck', { 'branch': 'main' }
Plug 'itchyny/lightline.vim' "下部のステータスライン
Plug 'Yggdroot/indentLine'
Plug 'mechatroner/rainbow_csv'
" 便利機能
Plug 'tpope/vim-commentary' " gccでコメントアウトできる
Plug 'justinmk/vim-sneak' " s + 二文字で検索
" Git
Plug 'airblade/vim-gitgutter'
" インテリジェンス
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'ervandew/supertab' " タブで補完を選択
" シンタックスハイライト＆インデント
Plug 'ap/vim-css-color'

Plug 'pangloss/vim-javascript'
Plug 'leafgarland/typescript-vim'
Plug 'maxmellon/vim-jsx-pretty'
" markdown目次
Plug 'mzlogin/vim-markdown-toc'
call plug#end()


" -------------------------------------------------------
" プラグイン関連のスクリプト
" -------------------------------------------------------
autocmd ColorScheme * highlight Comment ctermfg=240 guifg=#555555
" NERDTreeを自動表示する
if !argc()
  autocmd VimEnter * NERDTree|normal gg3j
endif
" タブで補完を選択するときに下向きに選択していく
let g:SuperTabDefaultCompletionType = "<c-n>"
let g:coc_disable_startup_warning = 1
let g:sneak#label = 1
" set filetypes as typescriptreact
autocmd BufNewFile,BufRead *.tsx,*.jsx set filetype=typescriptreact

let g:indentLine_conceallevel = 0
set conceallevel=0

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
" set cindent " 賢いインデントモード (polyglotのオートインデントが使われるので無効)
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

" カーソルの形
let &t_SI.="\e[6 q"
let &t_EI.="\e[2 q"
let &t_SR.="\e[4 q"


" key map
let mapleader = "\<Space>"
nnoremap j gj
nnoremap k gk
nnoremap n nzz
nnoremap N Nzz
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
nnoremap <silent> <Leader>e :NERDTreeToggle<CR>
nnoremap <silent> <Leader><Leader> :let @/ = '\<' . expand('<cword>') . '\>'<CR>:set hlsearch<CR>
nnoremap p ]p
nnoremap P ]P
nnoremap Y y$
nnoremap J 10j
nnoremap K 10k
nnoremap G Gzz
nnoremap U <C-r>
nnoremap H I<Esc>
nnoremap L $
nnoremap <C-o> mzo<Esc>`z
nnoremap <C-S-o> mzO<Esc>`z
nnoremap x "_x
" nnoremap s "_s
inoremap <silent> jj <Esc>
vnoremap < <gv
vnoremap > >gv
nmap <silent> <F3> <ESC>i<C-R>=strftime("%Y/%m/%d")<CR><CR><ESC>
nmap <silent> <Esc><Esc> :nohlsearch<CR><Esc>
nmap # <Leader><Leader>:%s/<C-r>///g<Left><Left>
imap <silent> <F3> <C-R>=strftime("%Y/%m/%d")<CR>

" search
set ignorecase
set smartcase
set incsearch
set wrapscan
set hlsearch

" theme
syntax enable
if exists('+termguicolors')
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
  set termguicolors
endif
colorscheme spaceduck
let g:lightline = {
      \ 'colorscheme': 'spaceduck',
      \ }

filetype plugin indent on
