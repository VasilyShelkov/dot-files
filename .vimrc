set nocompatible
filetype off

set t_Co=256
set termguicolors
syntax on

" Set the runtime path to include Vundle and initialization
set rtp+=~/.vim/bundle/Vundle.vim

if $TMUX == ''
  set clipboard+=unnamed
endif

" List of plugins
call vundle#begin()
Plugin 'VundleVim/Vundle.vim'

Plugin 'mhinz/vim-startify'
Plugin 'ervandew/supertab'
Plugin 'moll/vim-node'
Plugin 'raimondi/delimitmate'
Plugin 'othree/html5.vim'
Plugin 'elzr/vim-json'
Plugin 'bronson/vim-trailing-whitespace'
Plugin 'myusuf3/numbers.vim'
Plugin 'tpope/vim-repeat'
Plugin 'othree/jspc.vim'
Plugin 'jparise/vim-graphql'
Plugin 'pangloss/vim-javascript'
Plugin 'jelera/vim-javascript-syntax'
let g:javascript_plugin_flow = 1

Plugin 'flowtype/vim-flow'
" locally installed flow
let g:flow#autoclose = 1
let local_flow = finddir('node_modules', '.;') . '/.bin/flow'
if matchstr(local_flow, "^\/\\w") == ''
  let local_flow= getcwd() . "/" . local_flow
endif
if executable(local_flow)
  let g:flow#flowpath = local_flow
endif

Plugin 'mileszs/ack.vim'
let g:ackprg = 'ag --vimgrep'

Plugin 'airblade/vim-gitgutter'
let g:gitgutter_grep_command = 'grep -e'

Plugin 'mxw/vim-jsx'
let g:jsx_ext_required = 0

" quick navigation to visible letter
Plugin 'easymotion/vim-easymotion'
map  f <Plug>(easymotion-bd-f)
map  F <Plug>(easymotion-bd-f)

"  useful commenting plugin
Plugin 'scrooloose/nerdcommenter'
let g:NERDSpaceDelims = 1
let g:NERDTrimTrailingWhitespace = 1

" status bar at bottom
Plugin 'bling/vim-airline'
let g:airline_powerline_fonts = 1
set laststatus=2

" fuzzy search with Ctrl+p
Plugin 'kien/ctrlp.vim'
map ,b :CtrlPBuffer<CR>
let g:ctrlp_map = '<c-p>'
let g:ctrlp_cmd = 'CtrlP'
let g:ctrlp_working_path_mode = 'ra'
" Exclude the following:
set wildignore+=*/tmp/*,*.so,*.swp,*.zip     " MacOSX/Linux
let g:ctrlp_custom_ignore = 'node_modules\|DS_Store\|git'

" surrounding text
Plugin 'tpope/vim-surround'

" navigation tree
Plugin  'scrooloose/nerdtree'
map ,p :NERDTreeToggle<CR>
nmap ,n :NERDTreeFind<CR>
let NERDTreeIgnore=['node_modules']

" nerdtree git plugin
Plugin 'Xuyuanp/nerdtree-git-plugin'

" file extension icons
Plugin 'ryanoasis/vim-devicons'
set encoding=utf8
set guifont=Droid\ Sans\ Mono\ for\ Powerline\ Plus\ Nerd\ File\ Types:h12

Plugin 'scrooloose/syntastic'
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_loc_list_height = 5
let g:syntastic_auto_loc_list = 0
let g:syntastic_check_on_open = 0
let g:syntastic_check_on_wq = 0
let g:syntastic_javascript_checkers = ['eslint']
" set autochdir
lcd %:p:h
autocmd BufEnter * let b:syntastic_javascript_eslint_exec = system('echo -n $(npm bin)/eslint')
let g:syntastic_error_symbol = '▶'
highlight link SyntasticErrorSign SignColumn
let g:syntastic_warning_symbol = '▶'
highlight link SyntasticWarningSign SignColumn

call vundle#end()
" end of plugins
"
" Theme color
Plugin 'morhetz/gruvbox'
set background=dark
autocmd vimenter * ++nested colorscheme gruvbox


" quicker window movement
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-h> <C-w>h
nnoremap <C-l> <C-w>l

" tab to last buffer to make it easy to go to the last file you were in
nmap <Tab> :b#<CR>

" Turn on file type detection.
filetype plugin indent on

syntax enable

" Display the mode you're in.
set showmode

" handle multiple buffer better
set hidden

" enhanced command line completion
set wildmenu

" Complete files like a shell.
set wildmode=list:longest

" case-sensitive if expression contains a capital letter
set smartcase

" Intuitive backspacing
set backspace=indent,eol,start

" show line numbers.
set number

" show cursor position.
set ruler

" Turn of .swp files
set noswapfile

" Turn text wrap off
set wrap!

" Highlight matches.
set hlsearch

" Highlight matches as you type
set incsearch

" Set the terminal's title
set title

" Don't make a backup before overwriting a file
set nobackup
set nowritebackup

" Enable system clipboard
if $TMUX == ''
	set clipboard+=unnamed
endif

" Global tab width.
set tabstop=2
set shiftwidth=2
set expandtab

set autoindent

" setting the curor line highlighted
augroup CursorLine
  au!
    au VimEnter,WinEnter,BufWinEnter * setlocal cursorline
      au WinLeave * setlocal nocursorline
    augroup END
    hi CursorLine ctermbg=240
    hi Normal ctermbg=none

" Abbreviations
ab cl, console.log('==========>', );<ESC>hhi
ab des, describe('', () => {<CR>});<ESC>O
ab it, it('', () => {<CR>});<ESC>O

" Brief help
" :PluginList       - lists configured plugins
" :PluginInstall    - installs plugins; append `!` to update or just :PluginUpdate
" :PluginSearch foo - searches for foo; append `!` to refresh local cache
" :PluginClean      - confirms removal of unused plugins; append `!` to auto-approve removal
