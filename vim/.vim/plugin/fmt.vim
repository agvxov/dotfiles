" fmt.vim - A Vim plugin to format text using the POSIX fmt command
" Maintainer: anon8697
" License: Public Domain
" Last Change: 2025 Mar 14

function! Fmt(width, from, to)
    " Width precedence:
    "  argument > &textwidth > 80
    let l:width = empty(a:width) ? (&textwidth > 0 ? &textwidth : 80) : a:width

    let l:cmd = 'fmt -w ' . l:width
    let l:formatted = systemlist(l:cmd, getline(a:from, a:to))
    if v:shell_error
        echoerr "fmt failed"
        return
    endif
    
    execute a:from . ',' . a:to . 'delete'
    call append(a:from - 1, l:formatted)
endfunction

" You should be invoking this command. E.g.:
"    :Fmt         - format the whole document using textwidth or 80 if its disabled
"    :Fmt 100     - format the whole document using width 100
"    :'<,'>Fmt30  - format the current selection using width 30
command! -range=% -nargs=? Fmt call Fmt(<q-args>, <line1>, <line2>)
