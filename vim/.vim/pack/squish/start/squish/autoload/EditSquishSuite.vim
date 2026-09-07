function! EditSquishSuite#IsSquishRoot(dir) abort
    return fnamemodify(a:dir, ':t') =~# '^suite_'
      \ && filereadable(a:dir . '/suite.conf')
endfunction

function! EditSquishSuite#FindSuiteRoot(startdir) abort
    " to absolute
    let l:dir = fnamemodify(a:startdir, ':p')

    while 1
        if EditSquishSuite#IsSquishRoot(l:dir)
            return l:dir
        endif

        let l:parent = fnamemodify(l:dir, ':h')

        " system root
        if l:parent ==# l:dir
            return ''
        endif

        let l:dir = l:parent
    endwhile
endfunction

function! EditSquishSuite#GetStartDir() abort
    let l:bufname = expand('%:p')
    if l:bufname !=# ''
        return fnamemodify(l:bufname, ':h')
    else
        return getcwd()
    endif
endfunction

" tab completion for EditSquishSuite#Edit()
function! EditSquishSuite#Complete(ArgLead, CmdLine, CursorPos) abort
    let l:root = EditSquishSuite#FindSuiteRoot(EditSquishSuite#GetStartDir())
    if l:root ==# ''
        return []
    endif

    let l:candidates = []

    " direct files in suite root
    for l:f in glob(l:root . '/*', 0, 1)
        if filereadable(l:f)
            call add(l:candidates, fnamemodify(l:f, ':t'))
        endif
    endfor

    " shared files displayed as their basename
    let l:shared = l:root . '/shared/scripts'
    if isdirectory(l:shared)
        for l:f in glob(l:shared . '/*', 0, 1)
            if filereadable(l:f)
                call add(l:candidates, fnamemodify(l:f, ':t'))
            endif
        endfor
    endif

    " test.* files displayed as their tst_* dirs
    for l:tst in glob(l:root . '/tst_*/', 0, 1)
        let l:name = fnamemodify(substitute(l:tst, '/$', '', ''), ':t')
        if index(l:candidates, l:name) < 0
            call add(l:candidates, l:name)
        endif
    endfor

    " filter by user input
    return filter(l:candidates, 'v:val =~# "^" . a:ArgLead')
endfunction

function! EditSquishSuite#Edit(arg) abort
    let l:root = EditSquishSuite#FindSuiteRoot(EditSquishSuite#GetStartDir())
    if l:root ==# ''
        echoerr 'EditSquishSuite: no suite.conf found — not inside a Squish suite'
        return
    endif

    " direct file
    let l:direct = l:root . '/' . a:arg
    if filereadable(l:direct)
        execute 'edit ' . fnameescape(l:direct)
        return
    endif

    " shared file
    let l:shared = l:root . '/shared/scripts/' . a:arg
    if filereadable(l:shared)
        execute 'edit ' . fnameescape(l:shared)
        return
    endif

    " test.* file
    let l:test_dir = l:root . '/' . a:arg
    if isdirectory(l:test_dir)
        let l:tests = glob(l:test_dir . '/test.*', 0, 1)
        if !empty(l:tests)
            execute 'edit ' . fnameescape(l:tests[0])
            return
        endif
    endif

    echoerr 'EditSquishSuite: cannot resolve "' . a:arg . '" to a file'
endfunction
