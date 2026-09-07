" syntax/suiteconf.vim — Squish suite.conf syntax highlighting
if exists("b:current_syntax")
    finish
endif

" Comments
" Squish technically does not document the existence of comments,
"  but all errors are silently ignored, so its irrelevant what the parser thinks
syntax match suiteconfComment /^#.*/

" Documented keys
syntax keyword suiteconfKey
    \ AUT
    \ CLASSPATH
    \ CWD
    \ ENVVARS
    \ HOOK_SUB_PROCESSES
    \ IMPLICITAUTSTART
    \ LANGUAGE
    \ NAMINGSCHEME
    \ OBJECTMAP
    \ TEST_CASES
    \ WRAPPERS
    \ USE_WHITELIST

" Undocumented keys
syntax keyword suiteconfKey
    \ VERSION
    \ OBJECTMAPSTYLE

" Boolean
syntax match suiteconfBool /\(true\|false\|0\|1\)/

" Errorous spaces around '='
syntax match suiteconfSpaceError / \+=/
syntax match suiteconfSpaceError /= \+/

" Assignment
syntax match suiteconfEquals /=/

" Generic value string
syntax match suiteconfValue /\(=\)\@<=.\+$/

" ---

highlight default link suiteconfComment  Comment
highlight default link suiteconfKey      Keyword
highlight default link suiteconfBool     Boolean
highlight default link suiteconfValue    String
highlight default link suiteconfEquals   Operator

highlight default suiteconfSpaceError ctermbg=1 ctermfg=15 guibg=#cc0000 guifg=#ffffff

let b:current_syntax = "suiteconf"
