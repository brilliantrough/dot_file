"True Color
set t_Co=256 
if has("termguicolors")
    " fix bug for vim
    set t_8f=[38;2;%lu;%lu;%lum " ^[ is ^v+<ESC>
    set t_8b=[48;2;%lu;%lu;%lum " ^[ is ^v+<ESC>
    " enable true color
    set termguicolors
endif

set nocompatible
filetype on
filetype indent on
filetype plugin on
filetype plugin indent on

syntax on

set fileencodings=utf-8,gbk
set shortmess+=I " Disable the default Vim startup message.
set showcmd		" Show (partial) command in status line.
set showmatch		" Show matching brackets.	
set hlsearch "high light search, annoying
set autowrite		" Automatically save before commands like :next and :make
set hidden " Hide buffers when they are abandoned
set ignorecase " Do case insensitive matching
set smartcase " Do smart case matching
set incsearch " Incremental search
setlocal noswapfile " 不要生成swap文件
set bufhidden=hide " 当buffer被丢弃的时候隐藏它
" colorscheme molokai" 设定配色方案

set number " Show line numbers.
set relativenumber
" set nowrap " do not wrap lines
set laststatus=2
set backspace=indent,eol,start
set cursorline " 突出显示当前行
set ruler " 打开状态栏标尺
set shiftwidth=4 " 设定 << 和 >> 命令移动时的宽度为 4
set softtabstop=4 " 使得按退格键时可以一次删掉 4 个空格
set tabstop=4 " 设定 tab 长度为 4
set nobackup " 覆盖文件时不备份
set autochdir " 自动切换当前目录为当前文件所在的目录
set backupcopy=yes " 设置备份时的行为为覆盖
"Disable audible bell because it's annoying.
set noerrorbells visualbell t_vb= 
set noerrorbells " 关闭错误信息响铃
set novisualbell " 关闭使用可视响铃代替呼叫
set t_vb= " 置空错误铃声的终端代码
set matchtime=2 " 短暂跳转到匹配括号的时间
set magic " 设置魔术
set smartindent " 开启新行时使用智能自动缩进
set cmdheight=1 " 设定命令行的行数为 1
set laststatus=2 " 显示状态栏 (默认值为 1, 无法显示状态栏)
set statusline=\ %<%F[%1*%M%*%n%R%H]%=\ %y\ %0(%{&fileformat}\ %{&encoding}\ Ln\ %l,\ Col\ %c/%L%) " 设置在状态行显示的信息
set mouse+=a
set tw=0
set fo+=t

set pumblend=15 " 补全菜单透明
set pumheight=18 " 补全菜单太长
set foldclose=all "disable all fold, seems useless
set foldmethod=syntax " 设置语法折叠
set foldcolumn=0 " 设置折叠区域的宽度
hi CocMenuSel ctermbg=109 guibg=#13354A " 设置Coc颜色
setlocal foldlevel=1 " 设置折叠层数为 1
set fen " fold enable, = set foldenable
set nofen " do not fold anything, = set nofoldenable
autocmd FileType * exe "normal zR"
nnoremap </> @=((foldclosed(line('.')) < 0) ? 'zc' : 'zo')<CR> " 用 / 来开关折叠

" Unbind some useless/annoying default key bindings.
nmap Q <Nop> " 'Q' in normal mode enters Ex mode. You almost never want this.

" :version must have '+clipboard'
" If not, you mus install vim-gtk3
vnoremap <C-Y> "+y
vnoremap <C-D> "+d
nnoremap <C-P> "+p
inoremap <C-P> <ESC>"+p
nnoremap <A-Z> :set wrap! " useless. cannot switch. 

nnoremap J <C-E>
nnoremap K <C-Y>
nnoremap H zh
nnoremap L zl
nnoremap QQ :q!<CR>


" nnoremap <Left>  :echoe "Use h"<CR>
" nnoremap <Right> :echoe "Use l"<CR>
" nnoremap <Up>    :echoe "Use k"<CR>
" nnoremap <Down>  :echoe "Use j"<CR>
" " ...and in insert mode
" inoremap <Left>  <ESC>:echoe "Use h"<CR>
" inoremap <Right> <ESC>:echoe "Use l"<CR>
" inoremap <Up>    <ESC>:echoe "Use k"<CR>
" inoremap <Down>  <ESC>:echoe "Use j"<CR>





" vim-plug
" :PlugInstall
" :PlugStatus
" :PlugClean
" :PlugUpdate

let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
let mapleader = "<space>"

call plug#begin()

Plug 'tomasr/molokai'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
let g:airline_theme = 'badwolf'

Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-fugitive'
Plug 'preservim/nerdtree'
let NERDTreeShowHidden=1

Plug 'Yggdroot/indentLine'
Plug 'tmsvg/pear-tree'
Plug 'godlygeek/tabular'
Plug 'scrooloose/syntastic'
"Plug 'altercation/vim-colors-solarized'
"Plug 'majutsushi/tagbar'
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'lervag/vimtex'
Plug 'ctrlpvim/ctrlp.vim'
let g:ctrlp_map = '<c-p>' " do not use <c-p> as ^p for paste
let g:ctrlp_cmd = 'CtrlP'

Plug 'plasticboy/vim-markdown'
Plug 'ferrine/md-img-paste.vim'
Plug 'mileszs/ack.vim'
Plug 'easymotion/vim-easymotion'
Plug 'christoomey/vim-tmux-navigator'
Plug 'kana/vim-operator-user'
Plug 'rhysd/vim-clang-format'
Plug 'mzlogin/vim-markdown-toc'
Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && yarn install' }
Plug 'morhetz/gruvbox' " 配色插件
Plug 'ryanoasis/vim-devicons' " emoji 图标
Plug 'preservim/nerdcommenter'
Plug 'luochen1990/rainbow' " 彩虹括号
let g:rainbow_active = 1

Plug 'kkoomen/vim-doge' " 自动生成 python 函数/类文档
"let g:doge_doc_standard_python = 'numpy'
"let g:doge_doc_standard_python = 'google'
let g:doge_doc_standard_python = 'reST'

Plug 'sheerun/vim-polyglot'
Plug 'dccsillag/magma-nvim', { 'do': ':UpdateRemotePlugins' }
Plug 'github/copilot.vim'
Plug 'tpope/vim-obsession'
Plug 'untitled-ai/jupyter_ascending.vim'

call plug#end()
" markdown config
 " :MarkdownPreviewToggel
let g:mkdp_path_to_chrome = '/usr/bin/firefox'
let g:mkdp_markdown_css = ''
let g:molokai_original = 1

" Coc warning
let g:coc_disable_startup_warning = 1 


 " indentLine
let g:indentLine_enabled = 1
let g:indent_guides_guide_size = 1
let g:indent_guides_start_level = 2
let g:indentLine_char_list = ['|', '¦', '┆', '┊']


let g:coc_global_extensions = [
	\ 'coc-css',
	\ 'coc-diagnostic',
	\ 'coc-docker',
	\ 'coc-eslint',
	\ 'coc-explorer',
	\ 'coc-flutter-tools',
	\ 'coc-gitignore',
	\ 'coc-html',
	\ 'coc-import-cost',
	\ 'coc-java',
	\ 'coc-jest',
	\ 'coc-json',
	\ 'coc-lists',
	\ 'coc-omnisharp',
	\ 'coc-prettier',
	\ 'coc-prisma',
	\ 'coc-pyright',
	\ 'coc-snippets',
	\ 'coc-sourcekit',
	\ 'coc-stylelint',
	\ 'coc-syntax',
	\ 'coc-tasks',
	\ 'coc-translator',
	\ 'coc-tsserver',
	\ 'coc-vetur',
	\ 'coc-vimlsp',
	\ 'coc-yaml',
	\ 'coc-vimtex',
	\ 'coc-texlab',
	\ 'coc-highlight',
	\ 'coc-clang-format-style-options',
    \ 'coc-clangd',
	\ 'coc-snippets',
	\ 'coc-vimlsp',
	\ 'coc-yank']
function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()
" inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"
inoremap <silent><expr> <cr> coc#pum#visible() ? coc#_select_confirm() : "\<C-g>u\<CR>"
inoremap <expr> <Tab> coc#pum#visible() ? coc#pum#next(1) : "\<Tab>"
inoremap <expr> <S-Tab> coc#pum#visible() ? coc#pum#prev(1) : "\<S-Tab>"
inoremap <silent><expr> <c-space> coc#refresh()
function! Show_documentation()
	call CocActionAsync('highlight')
	if (index(['vim','help'], &filetype) >= 0)
		execute 'h '.expand('<cword>')
	else
		call CocAction('doHover')
	endif
endfunction
nnoremap <LEADER>h :call Show_documentation()<CR>

" " set runtimepath^=~/.config/nvim/coc-extensions/coc-flutter-tools/
" let g:coc_node_args = ['--nolazy', '--inspect-brk=6045']
" let $NVIM_COC_LOG_LEVEL = 'debug'
" let $NVIM_COC_LOG_FILE = '/Users/david/Desktop/log.txt'

nnoremap <silent><nowait> <LEADER>d :CocList diagnostics<cr>
nmap <silent> <LEADER>- <Plug>(coc-diagnostic-prev)
nmap <silent> <LEADER>= <Plug>(coc-diagnostic-next)
nnoremap <c-c> :CocCommand<CR>
" Text Objects
xmap kf <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap kf <Plug>(coc-funcobj-i)
omap af <Plug>(coc-funcobj-a)
xmap kc <Plug>(coc-classobj-i)
omap kc <Plug>(coc-classobj-i)
xmap ac <Plug>(coc-classobj-a)
omap ac <Plug>(coc-classobj-a)
" Useful commands
nnoremap <silent> <space>y :<C-u>CocList -A --normal yank<cr>
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gv :vsp<CR><Plug>(coc-definition)<C-W>L
" nmap <silent> gD :tab sp<CR><Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
" nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nmap <leader>rn <Plug>(coc-rename)
nmap tt :CocCommand explorer<CR>
" coc-translator
nmap ts <Plug>(coc-translator-p)
" Remap for do codeAction of selected region
function! s:cocActionsOpenFromSelected(type) abort
  execute 'CocCommand actions.open ' . a:type
endfunction
xmap <leader>a  <Plug>(coc-codeaction-selected)
nmap <leader>aw  <Plug>(coc-codeaction-selected)w
" coctodolist
" nnoremap <leader>tn :CocCommand todolist.create<CR>
" nnoremap <leader>tl :CocList todolist<CR>
" nnoremap <leader>tu :CocCommand todolist.download<CR>:CocCommand todolist.upload<CR>
" coc-tasks
noremap <silent> <leader>ts :CocList tasks<CR>
" coc-snippets
imap <C-m> <Plug>(coc-snippets-expand)
vmap <C-e> <Plug>(coc-snippets-select)
let g:coc_snippet_next = '<tab>'
let g:coc_snippet_prev = '<c-n>'
imap <C-e> <Plug>(coc-snippets-expand-jump)
autocmd BufRead,BufNewFile tsconfig.json set filetype=jsonc
autocmd CursorHold * silent call CocActionAsync('highlight')
" inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
" inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

" pear-tree"
let g:pear_tree_repeatable_expand = 0 "为了不消除另一个匹配项，在敲回车的时候"
imap <c-x> <Plug>(PearTreeExpand)


" vimtex"
let g:tex_flavor = 'latex'
let g:vimtex_quickfix_mode = 0
let g:vimtex_view_general_viewer = 'zathura'
let g:vimtex_view_method = 'zathura'
let g:vimtex_toc_config = {
\ 'name' : 'TOC',
\ 'layers' : ['content', 'todo', 'include'],
\ 'split_width' : 25,
\ 'todo_sorted' : 0,
\ 'show_help' : 1,
\ 'show_numbers' : 1,
\}
let g:vimtex_compiler_latexmk = { 
        \ 'executable' : 'latexmk',
        \ 'options' : [ 
        \   '-xelatex',
        \   '-file-line-error',
		\	'-shell-escape',
        \   '-synctex=1',
        \   '-interaction=nonstopmode',
        \ ],
        \}
let g:vimtex_compiler_latexmk_engines = {
    \ '_'                : '-xelatex',
    \}
" clang-format
" function! Formatonsave()
"   let l:formatdiff = 1
" 	pyf /home/pzy000/llvm/tools/clang/tools/clang-format/clang-format.py
" endfunction
" autocmd BufWritePre *.h,*.cc,*.c,*.cpp call Formatonsave()

" vim-clang-format
"let g:clang_format#style_options = {
"            \ "AccessModifierOffset" : -4,
"            \ "AllowShortIfStatementsOnASingleLine" : "true",
"            \ "AlwaysBreakTemplateDeclarations" : "true",
"            \ "Standard" : "C++11"}

" map to <Leader>cf in C++ code
autocmd FileType c,cpp,objc nnoremap <buffer><Leader>cf :<C-u>ClangFormat<CR>
autocmd FileType c,cpp,objc vnoremap <buffer><Leader>cf :ClangFormat<CR>
" if you install vim-operator-user
autocmd FileType c,cpp,objc map <buffer><Leader>x <Plug>(operator-clang-format)
" Toggle auto formatting:
nmap <Leader>C :ClangFormatAutoToggle<CR>
let g:clang_format#auto_format_on_insert_leave=0
let g:clang_format#detect_style_file=1
let g:clang_format#auto_format=1
" autocmd FileType c ClangFormatAutoEnable

imap <c-l> <Right>
imap <c-h> <Left>
imap <c-j> <Down>
imap <c-k> <Up>
imap <c-s> <ESC>:w<cr>
imap <c-z> <ESC>ui
imap <c-q> <Esc>
nmap <c-s> :w<cr>
nmap <c-e> :terminal<cr>
nmap <c-n> :NERDTreeToggle<CR>:vert res 20<CR>
nmap <C-_>   <Plug>NERDCommenterToggle
vmap <C-_>   <Plug>NERDCommenterToggle<CR>
nmap <c-b> :vert res 80<CR>
nmap <c-t> :sp<CR><C-j>:term<CR>:res 10<CR>
nmap <C-tab> :bn<cr>
nmap <tab> :tabn<cr>
nmap <S-tab> :tabp<cr>
nmap <Leader>q :q<cr>
nmap <c-Right> :vert res +5<cr>
nmap <c-Left> :vert res -5<cr>
nmap <c-Up> :res +2<cr>
nmap <c-Down> :res -2<cr>
nmap <c-6> :bn<cr>
colorscheme gruvbox
set background=dark
tmap <ESC> <C-\><C-n>
tmap <c-h> <ESC><c-h>
tmap <c-l> <ESC><c-l>
tmap <c-k> <ESC><c-k>

" magma-nvim settings
nnoremap <silent><expr> <LocalLeader>r  :MagmaEvaluateOperator<CR>
nnoremap <silent>       <LocalLeader>rr :MagmaEvaluateLine<CR>
xnoremap <silent>       <LocalLeader>r  :<C-u>MagmaEvaluateVisual<CR>
nnoremap <silent>       <LocalLeader>rc :MagmaReevaluateCell<CR>
nnoremap <silent>       <LocalLeader>rd :MagmaDelete<CR>
nnoremap <silent>       <LocalLeader>ro :MagmaShowOutput<CR>
nmap <silent> ga <Plug>(coc-codeaction-line)
xmap <silent> ga <Plug>(coc-codeaction-selected)
nmap <silent> gA <Plug>(coc-codeaction)

let g:magma_automatically_open_output = v:false
let g:magma_image_provider = "ueberzug"
