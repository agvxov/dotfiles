if exists('g:loaded_edit_squish_suite')
    finish
endif

let g:loaded_edit_squish_suite = 1

command! -nargs=1 -complete=customlist,EditSquishSuite#Complete
    \ EditSquishSuite call EditSquishSuite#Edit(<q-args>)

cnoreabbrev <expr> ess
    \ (getcmdtype() ==# ':' && getcmdline() ==# 'ess') ? 'EditSquishSuite' : 'ess'
