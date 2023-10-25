" Vim syntax file
" Language: idln
" Current Maintainer: SilentOcapi
" Last Change: 2022 jan 9
" TODO:

let b:current_syntax = "idln"

" DO NOT SCREW WITH THE ORDERING
" Head:
syn match	idlnRoot "^\w*"
syn match	idlnHead "^#?.*"
syn match	idlnFile " [\w\.]*"
syn match	idlnLine "[│├─└]"
syn match	idlnMeta "^\d* \w*,.*"

" Highlighting:
hi link idlnHead Comment
hi link idlnLine Label
hi link idlnMeta Function
hi link idlnFile Statement
hi idlnRoot cterm=bold ctermbg=11
