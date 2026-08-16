" autoload/markx/delete.vim
"
" MarkX - Richard Bentley-Green
"
" Auto-placement of signs in the left margin, in response to creation and
" deletion of marks, plus some extra mark-placement functions
"
" Defines a delete function that is rarely used if multimarks is not enabled,
" hence it's been moved from the main code to here
"
if exists('g:Markx_delete_loaded_autoload')
  finish
endif
const g:Markx_delete_loaded_autoload = 1

" Unplace all signs (not marks!) from a buffer or globally.
" Also, if multi-marks is in operation then delete all sign definitions
" associated with 'local' marks. We only delete the 'local' sign defs
" because there can be many of each of them, whereas there is only (at
" most) 1 of each 'global' sign def
"
" bufn - If zero then delete signs from all buffers in the current tab
"        If > 0 then the buffer to remove signs from
"
function markx#delete#deleteSigns(bufn)
  let l:splacedList = []
  if a:bufn
    let l:splacedList = sign_getplaced(a:bufn, {'group' : markx#signGroup()})
  else
    " Get a list of signs in all buffers

    " A note of which buffers we have processed
    let l:done = {}

    for l:winx in range(1, winnr('$'))
      let l:bufn = winbufnr(l:winx)
      if !has_key(l:done, l:bufn)
        " Get a list of signs for this buffer
        let l:signs = sign_getplaced(l:bufn, {'group' : markx#signGroup()})
        if len(l:signs[0]['signs'])
          call add(l:splacedList, l:signs[0])
        endif

        let l:done[l:bufn] = 1
      endif
    endfor

    " This will get a list of all buffers in all tabs
    "  let l:buflist = filter(range(1, bufnr('$')), 'bufexists(v:val)')
  endif

  " Scan through list of signs and delete them
  if len(l:splacedList)
    let l:bufx = 0
    while l:bufx < len(l:splacedList)
      let l:signs = l:splacedList[l:bufx]['signs']
      if len(l:signs)
        " At least one sign is placed for this buffer
        let l:bufn = l:splacedList[l:bufx]['bufnr']
        if !a:bufn || (l:bufn == a:bufn)
          " This buffer is of interest - delete all the signs placed in it
          let l:idx = 0
          while l:idx < len(l:signs)
            call markx#unplaceSign(l:bufn, nr2char(l:signs[l:idx]['id']))
            let l:idx += 1
          endwhile
        endif
      endif

      let l:bufx += 1
    endwhile
  endif
endfunction

" ------------------------------------------------------------------------------
" eof

