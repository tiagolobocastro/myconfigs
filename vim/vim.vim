call plug#begin(g:vimplugged)

  " Cock.Nvim
  Plug 'neoclide/coc.nvim', {'branch': 'release'}
  
  " Fzf
  Plug 'junegunn/fzf', { 'do': './install --all' }
  Plug 'junegunn/fzf.vim'
  
  " Ack
  Plug 'mileszs/ack.vim'

  " Vim Airline
  Plug 'vim-airline/vim-airline'
  Plug 'vim-airline/vim-airline-themes'

  " Nerd Tree
  Plug 'preservim/nerdtree'

  " Vim-Nix
  Plug 'LnL7/vim-nix'

call plug#end()

" Ack
" the_silver_searcher
if executable('ag')
  let g:ackprg = 'ag --vimgrep'
endif

cabbrev Ack Ack!

" Cock.Nvim
source $myvim/vim/coc-nvim.vim


" Vim airline
let g:airline_powerline_fonts=1
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#show_tabs = 1
let g:airline#extensions#tabline#show_tab_nr = 0
let g:airline#extensions#tabline#buffer_idx_mode = 1

nmap <leader>1 <Plug>AirlineSelectTab1
nmap <leader>2 <Plug>AirlineSelectTab2
nmap <leader>3 <Plug>AirlineSelectTab3
nmap <leader>4 <Plug>AirlineSelectTab4
nmap <leader>5 <Plug>AirlineSelectTab5
nmap <leader>6 <Plug>AirlineSelectTab6
nmap <leader>7 <Plug>AirlineSelectTab7
nmap <leader>8 <Plug>AirlineSelectTab8
nmap <leader>9 <Plug>AirlineSelectTab9

" Nerd Tree 
map <C-n> :NERDTreeToggle<CR>

" My Own Prefs
set number
set tabstop=4
set shiftwidth=4
set expandtab
set splitright 

" search will highlight matches
set hlsearch 
" clear highlight when done
nnoremap <silent> \\ : nohlsearch<CR>

nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

nnoremap <silent> ` : vertical terminal<CR>

