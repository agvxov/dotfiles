" NOTE: keys() & values() return their results in arbitrary order
let s:colorKeys   = ['red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'black', 'white', 'bold', 'italics', 'normal', 'reverse']
let s:colorValues = [ '31',    '32',     '33',   '34',      '35',   '36',    '30',    '37',    '1',       '3',      '0',       '7']

function! s:ColorSelected(id, result)
    let val = '\033[' . s:colorValues[a:result-1] . 'm'
    exec 'normal! i' . val
endfunction

function! ShowEscapeDictionary()
    call popup_menu(s:colorKeys, #{
        \ callback: 's:ColorSelected',
        \ })
endfunction

command! ShowEscapeDictionary call ShowEscapeDictionary()


let s:makeKeys   = ['target', 'star', 'first pre.', 'all new pre.', 'all pre.', 'uniq all pre.', 'basename target']
let s:makeValues = [     '@',    '%',          '<',            '?',        '+',             '^',               '*']

function! s:MakeSelected(id, result)
    let val = '$' . s:makeValues[a:result-1]
    exec 'normal! i' . val
endfunction

function! ShowMakeDictionary()
    call popup_menu(s:makeKeys, #{
        \ callback: 's:MakeSelected',
        \ })
endfunction

command! ShowMakeDictionary call ShowMakeDictionary()
