" Vim syntax file
" Language: Password-file

let b:current_syntax = "passwd"

" Matching:
syn match Email ".\+@.\+\..\+"
syn match Pin   "\<\d\+\>"

syn match PasswdPlus        "^+"    contained
syn match PasswdAlt         "(.*)"  contained
syn match PasswdDesignation "^+ .*" contains=PasswdPlus,PasswdAlt

" Highlighting:
hi link Email   Function
hi link Pin     Number

hi PasswdPlus ctermfg=208
hi link PasswdAlt         Title
hi link PasswdDesignation Comment
