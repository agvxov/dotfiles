" -------------
" ### LOOKS ###
" -------------
    set title
    set iconstring=Vim

    set listchars=tab:<·>,eol:¬,space:·,nbsp:⎵

    filetype on

    syntax on

    set nowrap          "do not wrap lines not fitting the screen
    set sidescroll=1    "do not jump half a screens whenever manuvering a line not fitting the screen

    set display=uhex    "display hex chats as <[hex]> instead of ^C and ~C

    set laststatus=2    "display status bar
    set ruler
    "set statusline+=%l,%c%V%=%P

    set visualbell      "flash instead of beeping

    "autocmd InsertEnter * silent !echo -ne "\e[1 q"
    "autocmd InsertLeave * silent !echo -ne "\e[0 q"
    let &t_VS = "\e[0 q"
    let &t_SI = "\e[1 q"
    let &t_EI = "\e[0 q"

    set showmatch       "highlight pair of paranthesies
    set hlsearch        "highlight search
    set wildmenu        "visual command auto complete

    se nostartofline    "Do not jump to first char of line when scolling

    set colorcolumn=100 " visual pseudo-margin on the right

    colorscheme knight

    set signcolumn=no

    set shortmess-=S    "show match count on search

" --------------------
" ### EASSE_OF_USE ###
" --------------------
    set backspace=2

    set undofile
    if isdirectory("/home/anon/")
        set undodir=/home/anon/stow/.cache/
        set directory=/home/anon/stow/.cache/
        set backupdir=/home/anon/stow/.cache/
    else
        set undodir=/tmp/
        set directory=/tmp/
        set backupdir=/tmp/
    endif

    set autoindent

    set ignorecase      "ignore case in searches
    set smartcase       "override ignorecase when upper case letters are used in the search
    set wildignorecase  "ignore case when auto completing file and directory names (does not to shells)

    set autoread        "chech for external changes in the file

    set autochdir

    set confirm         "when quiting an unsaved filed, do not fail, instead ask back whether the buffer shall be saved, not saved, or cancel the operation

    set mouse=a
    nnoremap <LeftMouse> <nop>

    set keywordprg=:call\ ContextualMan()\ \"   " better 'K' help

    set suffixes+=.info,.aux,.log,.dvi,.bbl,.out,.o,.lo,.obj    " ignore on completion

    set foldopen-=hor " do not unfold on horizontal movement

    " always respect # pragma region
    set foldmarker=#pragma\ region,#pragma\ endregion
    set foldmethod=marker

    " tabs/spaces
    set tabstop=4
    set shiftwidth=4
    set expandtab
    set softtabstop=4

" -----------------
" ### Functions ###
" -----------------
    function ContextualMan()
        let word = expand('<cword>')
        let cmd  = ":silent !"

        if &filetype == "vim"
            :help word
            return
        endif

        if &filetype == "c"
            let cmd .= "man -s 3,2 "
        elseif &filetype == "cpp"
            let cmd .= "man -s 3,2 " . word . "; [ $? == 16 ] && cppman "
        elseif &filetype == "python"
            let cmd .= "pydoc "
        elseif &filetype == "tcl"
            let cmd .= "man n "
        elseif &filetype == "bash" || &filetype == "sh"
            let cmd .= "man 1 "
        else
            let cmd .= "man 3 "
        endif

        let cmd .= word

        execute cmd
        redraw!
    endfunction

    function! ToUnicodeMathNotation(range)
        let superscript_table = {'\^0': '⁰', '\^1': '¹', '\^2': '²', '\^3': '³', '\^4': '⁴', '\^5': '⁵', '\^6': '⁶', '\^7': '⁷', '\^8': '⁸', '\^9': '⁹'}
        let subscript_table = {'ˇ0': '₀', 'ˇ1': '₁', 'ˇ2': '₂', 'ˇ3': '₃', 'ˇ4': '₄', 'ˇ5': '₅', 'ˇ6': '₆', 'ˇ7': '₇', 'ˇ8': '₈', 'ˇ9': '₉'}
        let replace_table = extend(superscript_table, subscript_table)
        for [key, value] in items(replace_table)
            execute ":" . a:range . "s/" . key . "/" . value . "/g"
        endfor
    endfunction

    function! Signcolumn_toggle()
        if &signcolumn == 'no'
            set signcolumn=yes
        elseif &signcolumn == 'yes'
            set signcolumn=no
        endif
    endfunction

    function! Drawit_toggle()
        if !exists("s:drawit_boolean")
            let s:drawit_boolean = 0
        endif
        if s:drawit_boolean
            DIstop
            let s:drawit_boolean = 0
        else
            DIstart
            let s:drawit_boolean = 1
        endif
    endfunction

    function! Programming_mode_toggle()
        if !exists("s:programming_mode_boolean")
            let s:programming_mode_boolean = 0
        endif

        if s:programming_mode_boolean
            let s:programming_mode_boolean = 0
            AcpDisable
        else
            let s:programming_mode_boolean = 1
            AcpEnable
        endif
    endfunction

    function! Spell_toggle()
        if !exists("s:spell_boolean")
            let s:spell_boolean = 0
        endif
        if s:spell_boolean
            set nospell
            let s:spell_boolean = 0
        else
            set spell spelllang=en_us
            let s:spell_boolean = 1
        endif
    endfunction

    function! Decancer()
        :%s/\n\W*{/ {/
        :%s/public /public\n/
        :%s/override /override\n/
        :%s/static /static\n/
    endfunction

    function! GitBlame()
      let l:filename    = expand('%')
      let l:line_number = line('.')
      execute 'silent !git blame -L ' . l:line_number . ',' . l:line_number . ' ' . l:filename
      redraw!
    endfunction

" --------------
" ### REMAPS ###
" --------------
"   Diff_mode:
        if &diff
            map <C-p>   :diffput<CR>
            map <C-n>   :diffget<CR>
        endif
"   Complete_on_tab:
        inoremap <expr> <TAB> pumvisible() ? "<C-y>" : "<TAB>"
        inoremap <expr> <CR>  pumvisible() ? "\<C-g>u\<CR>" : "\<C-g>u\<CR>"
        inoremap <expr> <C-j> pumvisible() ? "\<C-N>" : "<C-j>"
        inoremap <expr> <C-k> pumvisible() ? "\<C-P>" : "<C-k>"

"   Function_keys:
        " ### Visibility island
          " F1: toggle whitespace visibility
          map <F1>  :set invlist<CR>
          " F2: toggle visible line numbers
          map <F2>  :set nu!<CR>
          " F3: toggle sign column
          map <F3>  :call Signcolumn_toggle()<CR>
          " F4: unhighligh highlighted text
          map <F4>  :noh<CR>

        " ### Feature island
          " F5: Display Turbo Menu
          map <F5>  :call quickui#menu#open()<CR>
          " F6: compile with bake
          map <f6>  :!bake %:p<CR>
          " F7:
            " NOTHING YET
          " F8: toggle acp (auto suggest) plugin mode
          map <F8>  :call Programming_mode_toggle()<CR>

        " ### Call once in a while island
          " F9: copy file contents to clipboard
          map <F9>  miggVG"+y'izz
          " F10:
            noremap <F10> <Nop>
          " F11:
            noremap <F11> <Nop>
          " F12: reload file
          map <F12> :e!<CR>
          "noremap <F12> <Nop>

"   Tagbar_plugin:
        nmap <C-W>m :TagbarToggle<CR>

"   Misc:
        nnoremap gb :call GitBlame()<CR>

"------------------
" ### VARIABLES ###
"------------------
    let g:hitags_events = ["BufWrite"]
    let g:sigs_events   = ["BufWrite"]

" -------------
" ### NETRW ###
" -------------
    let g:netrw_keepdir = 0
    let g:netrw_banner = 0
    "let g:netrw_browse_split = 2
    let g:netrw_liststyle = 3

" ---------------
" ### QUICKUI ###
" ---------------
call quickui#menu#install('&Edit', [
            \ [ '&Drawit', ':call Drawit_toggle()'],
            \ [ '&Expandtab', ':set expandtab!'],
            \ [ '&Brace unf*', ':%s/\n\s*{/ {/g'],
            \ ])
call quickui#menu#install('&View', [
            \ [ '&Spell', ':call Spell_toggle()'],
            \ [ '&Netrw', ':Lex'],
            \ [ '&Diff',  ':diffthis'],
            \ ])
call quickui#menu#install('&Modify', [
            \ [ '&Remove trailing', ':%s/\s\+$//g'],
            \ [ '&Retab', ':retab!'],
            \ [ 'De&cancer', ':call Decancer()'],
            \ ])
call quickui#menu#install('&Development', [
            \ [ '&Ascii Escape', ':ShowEscapeDictionary'],
            \ [ '&Make special', ':ShowMakeDictionary'],
            \ [ '&Symbol map',   ':TagbarToggle', '<C-W>m'],
            \ ])

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
    "set title          " already called
endif

" ------------------


set formatoptions-=cro

" TEMP:
highlight DiffChange ctermbg=3

" AI notes:
"  <C-W>v<C-W>l
"  :new
"  :windo diffthis
