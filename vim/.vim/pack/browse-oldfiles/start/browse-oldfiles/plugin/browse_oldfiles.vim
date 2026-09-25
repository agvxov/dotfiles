function! s:BrowseOldfiles()
    " -- Create
    enew
    setlocal buftype=nofile bufhidden=wipe noswapfile
    setlocal cursorline nobuflisted
    
    silent! file oldfiles " set buffer name
    
    call append(0, v:oldfiles)

    setlocal readonly nomodifiable
    
    " -- Configure
    call cursor(1, 1)
    
    nnoremap <buffer> <CR> :call <SID>OpenFile()<CR>

    if !empty(globpath(&runtimepath, 'syntax/vimdir.vim'))
        setfiletype vimdir
    else
        setfiletype netrw
    endif
endfunction

function! s:OpenFile()
    let l:file = getline('.')
    if empty(l:file)
        return
    endif
    
    if filereadable(expand(l:file))
        let l:mru_buf = bufnr('%')
        execute 'edit ' . fnameescape(l:file)
    else
        echohl ErrorMsg
        echo 'File not found: ' . l:file
        echohl None
    endif
endfunction

command! BrowseOldfiles call s:BrowseOldfiles()
