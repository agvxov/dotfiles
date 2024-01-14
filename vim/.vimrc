" -------------
" ### LOOKS ###
" -------------
	set title
	"set titlestring=Vim
	set iconstring=Vim

	set tabstop=4
	set shiftwidth=4
	set expandtab

	set listchars=tab:<·>,eol:¬,space:·,nbsp:⎵

	syntax on

	set nowrap			"do not wrap lines not fitting the screen
	set sidescroll=1	"do not jump half a screens whenever manuvering a line not fitting the screen

	set display=uhex	"display hex chats as <[hex]> instead of ^C and ~C

	set laststatus=2 	"display status bar
	set ruler
	"set statusline+=%l,%c%V%=%P

	set visualbell		"flash instead of beeping; im not sure whether thats great or annoying

	"autocmd InsertEnter * silent !echo -ne "\e[1 q"
	"autocmd InsertLeave * silent !echo -ne "\e[0 q"
	let &t_VS = "\e[0 q"
	let &t_SI = "\e[1 q"
	let &t_EI = "\e[0 q"

	set showmatch 		"highlight pair of paranthesies
	set hlsearch 		"highlight search
	set wildmenu 		"visual command auto complete

	se nostartofline	"Do not jump to first char of line when scolling

	set colorcolumn=100 " pseudo margin at 80

	colorscheme knight

	set signcolumn=no

	set shortmess-=S	"show match count on search

" --------------------
" ### EASSE_OF_USE ###
" --------------------
	set bs=2
	set undodir=/home/anon/Master/un/
	set undofile

	set directory=/home/anon/Master/un/
	set backupdir=/home/anon/Master/un/

	set autoindent

	set ignorecase		"ignore case in searches
	set smartcase		"override ignorecase when upper case letters are used in the search
	set wildignorecase	"ignore case when auto completing file and directory names (does not to shells)

	set autoread 		"chech for external changes in the file

	set autochdir

	set confirm 		"when quiting an unsaved filed, do not fail, instead ask back whether the buffer shall be saved, not saved, or cancel the operation

	set noexpandtab

	set mouse=a
	nnoremap <LeftMouse> <nop>

	set keywordprg=:call\ ContextualMan()\ \"	" better 'K' help

	set suffixes+=.info,.aux,.log,.dvi,.bbl,.out,.o,.lo,.obj	" ignore on completion

	set foldopen-=hor " do not unfold on horizontal movement

	" always respect # pragma region
	set foldmarker=#pragma\ region,#pragma\ endregion
	set foldmethod=marker

" -----------------
" ### Functions ###
" -----------------
	function ContextualMan()
		let word = expand('<cword>')
		let cmd  = ":silent !"

		if &filetype == "cpp"
			let cmd .= "man 3 " . word . "; [ $? == 16 ] && cppman "
		elseif &filetype == "python"
			let cmd .= "pydoc "
		else
			if &filetype == "bash" || &filetype == "sh" 
				let cmd .= "man 1 "
			else
				let cmd .= "man 3 "
			endif
		endif

		let cmd .= word

		execute cmd
		redraw!
	endfunction

	function! Signcolumn_toggle()
		if &signcolumn == 'no'
			set signcolumn=yes
		elseif &signcolumn == 'yes'
			set signcolumn=no
		endif
	endfunction

	let s:drawit_boolean = 0
	function! Drawit_toggle()
		if s:drawit_boolean
			DIstop
			let s:drawit_boolean = 0
		else
			DIstart
			let s:drawit_boolean = 1
		endif
	endfunction

	let s:acp_boolean = 0
	function! Acp_toggle()
		if s:drawit_boolean
			AcpDisable
			let s:drawit_boolean = 0
		else
			AcpEnable
			let s:drawit_boolean = 1
		endif
	endfunction

	let s:spell_boolean = 0
	function! Spell_toggle()
		if s:drawit_boolean
			set nospell
			let s:drawit_boolean = 0
		else
			set spell spelllang=en_us
			let s:drawit_boolean = 1
		endif
	endfunction

" --------------
" ### REMAPS ###
" --------------
"	Diff_mode:
		if &diff
			map <C-p>	:diffput<CR>
			map <C-n>	:diffget<CR>
		endif
"	Complete_on_tab:
		inoremap <expr> <TAB> pumvisible() ? "<C-y>" : "<TAB>"
		inoremap <expr> <CR> pumvisible() ? "\<C-g>u\<CR>" : "\<C-g>u\<CR>"
		inoremap <expr> <C-j> pumvisible() ? "\<C-N>" : "<C-j>"
		inoremap <expr> <C-k> pumvisible() ? "\<C-P>" : "<C-k>"
" 	Function_keys:
		" ### Visibility island
		  " F1: toggle whitespace visibility
		  map <F1>	:set invlist<CR>
		  " F2: toggle visible line numbers
		  map <F2> 	:set nu!<CR>
		  " F3: toggle sign column
		  map <F3> 	:call Signcolumn_toggle()<CR>
		  " F4: unhighligh highlighted text
		  map <F4> 	:noh<CR>
		" ### Feature island
		  " F5: toggle spell check
		  "map <F5> 	:!aspell check %<CR>:e! %<CR>
		  map <F5> 	:call Spell_toggle()<CR>
		  " F6: reload ctags and its highlighting
		  map <f6>	:call Cpp_tags_run()<CR>
		  " F7: toggle DrawIt plugin mode
		  map <F7> 	:call Drawit_toggle()<CR>
		  " F8: toggle acp (auto suggest) plugin mode
		  map <F8> 	:call Acp_toggle()<CR>
		" ### Call once in a while island
		  " F9: copy file contents to clipboard
		  map <F9>	miggVG"+y'izz
		  " F12: reload file
		  map <F12>	:e!<CR>
"	Tagbar_plugin:
		nmap <C-W>m :TagbarToggle<CR>

"------------------
" ### VARIABLES ###
"------------------
	let $BASH_ENV = "/home/jacob/Desktop/minecraft mod/Linux/Vim/bash_aliases"
	let g:hitags_events = ["BufWrite"]

" -------------
" ### NETRW ###
" -------------
	let g:netrw_keepdir = 0
	let g:netrw_banner = 0
	"let g:netrw_browse_split = 2
	let g:netrw_liststyle = 3

" ------------
" ### TMUX ###
" ------------
function! Fname()
	if expand("%:t") != ""
		return expand("%:t")
	else
		return "vim"
	endif
endfunction

if exists('$TMUX')
	autocmd BufEnter * call system('tmux rename-window ' . Fname())
	autocmd VimLeave * call system('sh -c "sleep 1 && tmux setw automatic-rename" & disown')
	autocmd BufEnter * let &titlestring = expand("%:t")
	"set title			" already called
endif

"---###NOTES###---
	"https://vimawesome.com/plugin/syntastic#introduction

"" Souce VimScript9 settings
"source ~/.vimrc9

set formatoptions-=cro
