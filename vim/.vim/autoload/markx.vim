" autoload/markx.vim
"
" MarkX - Richard Bentley-Green, 22/03/2023
"
" Auto-placement of signs in the left margin, in response to creation and
" deletion of marks, plus some extra mark-placement functions
"
if exists('g:Markx_loaded_autoload')
  finish
endif
const g:Markx_loaded_autoload = 1

" ------------------------------------------------------------------------------
" Note:
" - Signs are named 'MarkX<N>' where '<N>' is the ASCII number of the mark character
" - Placed signs have Ids in the range ASCII(") to ASCII(}) - ie, 35 to 125
" - Local marks include 'a' to 'z', " ' ( ) . < > [ ] ^ ` { }
" - Global marks include 'A' to 'Z', '0' to '9'

const s:allLocalMarks = "abcdefghijklmnopqrstuvwxyz'<>[]`\"().^{}"
const s:allGlobalMarks = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

" A lookup table to determine the type of a mark
const s:mkTypes = 'x----pxx----x-nnnnnnnnnn--p-p--uuuuuuuuuuuuuuuuuuuuuuuuuup-px-pllllllllllllllllllllllllllx-x'

" The marks that the user wants displaying
let s:userLMarks = ''
let s:userPMarks = ''
let s:userXMarks = ''
let s:userUMarks = ''
let s:userNMarks = ''

" The local and global marks that the user wants displaying
let s:userLocalMarks = ''
let s:userGlobMarks = ''

" The marks that the user wants to consider for auto-selection placement.
" These are (must be) be a subset of s:userLMarks and s:userUMarks respectively
let s:autoLMarks = ''
let s:autoUMarks = ''

" The index into s:autoUMarks indicating the next mark to auto-place
" (the index into s:autoLMarks is defined per-buffer)
let s:autoA = 0

" Colour definitions for the signs
highlight default MarkXL ctermfg=214 ctermbg=0 cterm=bold guifg=#ffaf00 guibg=#000000 gui=bold
highlight default MarkXP ctermfg=108 ctermbg=0 cterm=bold guifg=#87af87 guibg=#000000 gui=bold
highlight default MarkXU ctermfg=109 ctermbg=0 cterm=bold guifg=#87afaf guibg=#000000 gui=bold
highlight default MarkXN ctermfg=175 ctermbg=0 cterm=bold guifg=#d787af guibg=#000000 gui=bold

" Sign priorities. The higher the value, the higher the priority (vim default is 10)
const s:sPriorL = get(g:, 'MarkxPriorL', 10)
const s:sPriorP = get(g:, 'MarkxPriorP', 10)
const s:sPriorU = get(g:, 'MarkxPriorU', 10)
const s:sPriorN = get(g:, 'MarkxPriorN', 10)

" The ASCII code for the first possible mark, and the span of all marks (NOT the
" same as the total number of marks)
const s:firstMarkNr = char2nr('"')
const s:spanMarkNrs = (char2nr('}') - char2nr('"')) + 1

" An optional character to place after the sign name. This may be an empty
" string or a single character. If defined, a character such as '>' or ':'
" is often used
const s:mktrail = get(g:, 'MarkxSignTrail', '')

" ----------------------------------
" Print a 'status' message to the command line
function s:PrintStatusMsg(msg)
  echohl StatusMsg | echo a:msg | echohl None
endfunction

" Print a 'warning' message to the command line
function s:PrintWarningMsg(msg)
  echohl WarningMsg | echo a:msg | echohl None
endfunction

" ----------------------------------
" Determine the type of mark
"
" mk - The mark name to assess
"
" Returns the type of mark;-
" '-' - Not a valid mark name
" 'l' - The mark is in the range 'a' to 'z'
" 'u' - The mark is in the range 'A' to 'Z'
" 'n' - The mark is in the range '0' to '9' (these marks cannot be explicitly set)
" 'p' - The mark is one of ' ` < > [ ]
" 'x' - The mark is one of " ( ) . ^ { } (these marks cannot be explicitly set)
"
function s:mkType(mk)
  let l:type = '-'
  let l:mkn = char2nr(a:mk) - s:firstMarkNr

  if (l:mkn >= 0) && (l:mkn < s:spanMarkNrs)
    let l:type = s:mkTypes[l:mkn]
  endif

  return l:type
endfunction

" Return a list of currently active marks (whether local or global) for
" the current buffer
"
" NOTE: If a mark is defined beyond the last line of the buffer then
"       it is considered 'invalid'. However, vim still maintains the
"       mark's position so if the file is extended to/beyond the
"       line the mark is defined at, the mark shall become valid.
"       The point is, vim does not automatically delete the 'invalid'
"       mark, so it's not the place of this script to delete it either.
"       Note also that if the mark is set beyond the end of an existing
"       line, it is NOT considered 'invalid' which is a bit inconsistent.
"       The upshot is that 'invalid' marks are treated by this function
"       as if they were valid and are returned
"
" mk - A string specifying a list of marks to consider and return status'
"      for
"
" Returns a list of active marks. Each list elements is itself a
" 3 element list; [0] = a single character (the mark's name),
" [1] = the line number the mark is attached to, and [2] = the
" buffer number that the mark is assigned to (this only applies
" if the mark is a global one; zero shall be returned for local
" marks)
"
function s:getMarks(mk)
  " Index into 'mk' string
  let l:mkx = 0

  " Number of lines in buffer. Invalid marks will have line number in excess of this
  let l:nlines = line('$')

  " Table of mark names that are set
  let l:currMarks = []
  let l:currIdx = 0

  while l:mkx < len(a:mk)
    let l:pos = getpos("'".a:mk[l:mkx])
    if l:pos[1]
      " Mark is set (though may be invalid) - record it
      call add(l:currMarks, [a:mk[l:mkx], l:pos[1], l:pos[0]])
      let l:currIdx += 1
    endif

    let l:mkx += 1
  endwhile

  return l:currMarks
endfunction

" Define a sign - if the sign already exists then it is just updated
"
" mk - The mark name to create the sign for
" type - The type of mark (as returned by mkType(). The type is assumed
"        to be valid
"
function s:makeSign(mk, type)
  " Select the colour for the sign
  let l:colour = 'MarkXP'
  if a:type ==# 'l'
    let l:colour = 'MarkXL'
  elseif a:type ==# 'u'
    let l:colour = 'MarkXU'
  elseif a:type ==# 'n'
    let l:colour = 'MarkXN'
  endif

  call sign_define('MarkX'.char2nr(a:mk), {'text' : a:mk.s:mktrail, 'texthl' : l:colour})
endfunction

" Refresh all signs in the current buffer
"
" globMarks - Optional. If specified, then this is the list of global marks
"             to consider
" localMarks - Optional. If specified then this is the list of local marks
"              to consider
"
function s:refreshSigns(globMarks = s:getMarks(s:userGlobMarks), localMarks = s:getMarks(s:userLocalMarks))
  " The buffer number associated with the current window
  let l:bufn = bufnr()

  " Get list of placed signs in the specified buffer
  let l:splacedtot = sign_getplaced(l:bufn, {'group' : 'MarkX'})
  let l:splaced = repeat([0], s:spanMarkNrs)
  let l:splacedCount = 0

  " Extract Id and line number for each defined sign
  if len(l:splacedtot)
    " Buffer exists - extract list of signs that we might be interested in
    let l:splacedlist = l:splacedtot[0]['signs']
    let l:idx = 0
    while l:idx < len(l:splacedlist)
      let l:id = l:splacedlist[l:idx]['id'] - s:firstMarkNr
      if (l:id >= 0) && (l:id < s:spanMarkNrs)
        " This is a sign we may be interested in - record its line number
        let l:splaced[l:id] = l:splacedlist[l:idx]['lnum']
        let l:splacedCount += 1
      endif
      let l:idx += 1
    endwhile
  endif

  " Refresh all the signs. This is done in two passes; the first pass handles
  " the marks local to the buffer ('a' to 'z' and . ' ` ^ < > [ ] { } ( ) "), and
  " the second pass handles the global marks ('A' to 'Z', '0' to '9')

  " Get list of active local marks for current buffer
  let l:mk = a:localMarks

  let l:pass = 0
  while l:pass < 2
    " Check each mark in turn
    let l:mkx = 0
    while l:mkx < len(l:mk)
      " The mark name, and the ASCII code equiv
      let l:mkName = l:mk[l:mkx][0]
      let l:mkCode = char2nr(l:mkName)

      " The priority of the associated sign
      let l:sPrior = 10
      if l:pass
        let l:sPrior = ((l:mkCode >= 65) && (l:mkCode <= 90)) ? s:sPriorU : s:sPriorN
      else
        let l:sPrior = ((l:mkCode >= 97) && (l:mkCode <= 122)) ? s:sPriorL : s:sPriorP
      endif

      " Index into l:placed[] array for this mark
      let l:idx = l:mkCode - s:firstMarkNr

      if l:splaced[l:idx]
        " Sign is placed for this mark
        if l:splaced[l:idx] != l:mk[l:mkx][1]
          " Sign line number doesn't match mark's line number - move the sign
          call sign_unplace('MarkX', {'buffer' : l:bufn, 'id' : l:mkCode})
          call sign_place(l:mkCode, 'MarkX', 'MarkX'.(l:mkCode), l:bufn, {'lnum' : l:mk[l:mkx][1], 'priority' : l:sPrior})
        endif

        " Mark sign as 'processed'
        let l:splaced[l:idx] = 0
        let l:splacedCount -= 1
      elseif !l:pass || (l:mk[l:mkx][2] == l:bufn)
        " On second pass, the buffer number of the 'global' mark must match the
        " specified buffer in order to be considered

        " Sign is not placed for this mark - place it
        call s:makeSign(l:mkName, s:mkType(l:mkName))
        call sign_place(l:mkCode, 'MarkX', 'MarkX'.(l:mkCode), l:bufn, {'lnum' : l:mk[l:mkx][1], 'priority' : l:sPrior})
      endif
      let l:mkx += 1
    endwhile

    if !l:pass
      " Prepare for second pass - get list of active global marks
      let l:mk = a:globMarks
    endif

    let l:pass += 1
  endwhile

  " Remove any signs that do not have associated marks
  let l:idx = 0
  while l:splacedCount && (l:idx < s:spanMarkNrs)
    if l:splaced[l:idx]
      " Sign is placed - remove it
      call sign_unplace('MarkX', {'buffer' : l:bufn, 'id' : l:idx + s:firstMarkNr})

      " Mark sign as 'processed'
      let l:splacedCount -= 1
    endif
    let l:idx += 1
  endwhile
endfunction

" Place a mark. The mark is always placed in the current buffer. The mark
" may already exist in which case it it moved. If the mark is a global type,
" it may be attached to some other buffer, in which case it is moved to the
" current buffer
"
" Only marks 'a' to 'z', 'A' to 'Z' and ' ` [ ] < > may be specified
"
" mk - The mark name to create, place, and add the sign for
" ln - The line number to set the mark at. If 0 is specified then the mark
"      is placed at the cursor position. If ln > 0 then the mark is placed
"      at line ln, column 0
" signed - If non-zero then this indicates that a sign should always be placed
"          for the mark 'mk'. If this is zero then the function will determine
"          for itself whether or not to display a sign
"
" Failure status. non-zero = failed (mark not set/moved). zero = success
"
function s:placeMark(mk, ln, signed)
  " Returned failure status
  let l:fail = 1

  " Type of mark
  let l:type = s:mkType(a:mk)

  if (l:type ==# 'n') || (l:type ==# 'x')
    call s:PrintWarningMsg('MarkX: Cannot place mark "'.a:mk.'" - not a mark that can be user-controlled')
  elseif l:type !=# '-'
    " Mark is valid - determine where to place it
    let l:ln = (a:ln) ? a:ln : line('.')
    let l:col = (a:ln) ? 0 : col('.')

    " Current buffer number
    let l:bufn = bufnr()

    " Determine if a sign should be placed for this mark or not
    let l:signed = a:signed || (stridx((l:type ==# 'l') ? s:userLMarks : ((l:type ==# 'u') ? s:userUMarks : s:userPMarks), a:mk) >= 0)

    " Mark is valid - get mark's current status
    let l:pos = getpos("'".a:mk)
    if (l:pos[1] != l:ln) || (l:pos[2] != l:col) || ((l:type ==# 'u') && (l:pos[0] != l:bufn))
      " Mark is local and its position (if set at all) needs changing, or it's
      " global and its position or associated buffer have changed, or the mark
      " is not set at all

      " The mark name converted to its ASCII code equiv
      let l:mkCode = char2nr(a:mk)

      if l:signed && (l:type ==# 'u') && l:pos[1] && (l:pos[0] != l:bufn)
        " Mark is global and is set in a buffer other than the specified one - Remove
        " associated sign (if any) from buffer to which the mark is currently associated
        call sign_unplace('MarkX', {'buffer' : l:pos[0], 'id' : l:mkCode})
      endif

      " Place or move the marker
      if a:ln
        " Place at specified line, column 0
        exe l:ln.'mark '.a:mk
      else
        " Place at cursor position
        exe 'normal! m'.a:mk
      endif

      if l:signed
        " The priority of the associated sign
        let l:sPrior = s:sPriorP
        if (l:type ==# 'l')
          let l:sPrior = s:sPriorL
        elseif l:type ==# 'u'
          let l:sPrior = s:sPriorU
        endif

        " Adjust the associated sign
        let l:totSign = sign_getplaced(l:bufn, {'group' : 'MarkX', 'id' : l:mkCode})
        let l:sign = l:totSign[0]['signs']
        if len(l:sign)
          " Sign is placed for this mark
          if l:sign[0]['lnum'] != l:ln
            " Sign line number doesn't match mark's line number - move the sign
            call sign_unplace('MarkX', {'buffer' : l:bufn, 'id' : l:mkCode})
            call sign_place(l:mkCode, 'MarkX', 'MarkX'.(l:mkCode), l:bufn, {'lnum' : l:ln, 'priority' : l:sPrior})
          endif
        else
          " Sign is not placed for this mark - place it
          call s:makeSign(a:mk, l:type)
          call sign_place(l:mkCode, 'MarkX', 'MarkX'.(l:mkCode), l:bufn, {'lnum' : l:ln, 'priority' : l:sPrior})
        endif
      endif

      let l:fail = 0
    endif
  else
    call s:PrintWarningMsg('MarkX: Cannot place mark "'.a:mk.'" - invalid mark')
  endif

  return l:fail
endfunction

" Unplace/remove a mark. If the mark is a global type then it may be defined
" in (and removed from) some buffer other than the current one
"
" Only marks 'a' to 'z', 'A' to 'Z' and ' ` < > [ ] may be specified
"
" mk - The mark name to remove
" Aglob - Only used for marks  'A' to 'Z'. If zero then a global mark
"         will only be deleted if it is associated with the local buffer.
"         Otherwise it shall always be deleted (regardless of the buffer it is
"         associated with)
" quiet - If non-zero then SOME error/warning messages shall be suppressed
"
function s:unplaceMark(mk, Aglob, quiet)
  " Type of mark
  let l:type = s:mkType(a:mk)

  if (l:type ==# 'n') || (l:type ==# 'x')
    if !a:quiet
      call s:PrintWarningMsg('MarkX: Cannot delete mark "'.a:mk.'" - not a mark that can be user-controlled')
    endif
  elseif l:type !=# '-'
    " Mark is valid - get mark's current status
    let l:pos = getpos("'".a:mk)
    if (l:type !=# 'u') || a:Aglob || !l:pos[0] || (l:pos[0] == bufnr())
      " Mark is associated with current buffer or caller has indicated that it should
      " be deleted regardless
      if l:pos[1]
        " Mark is set - unset it
        exe 'delmarks '.a:mk
      endif

      " The mark name converted to its ASCII code equiv
      let l:mkCode = char2nr(a:mk)

      " Unplace the sign for the mark (if it's placed). The sign may be in the
      " current buffer or (if the associated mark is global) in some other buffer
      if l:type ==# 'u'
        " Global mark - may have a buffer number that doesn't actually exist;
        " may be attached to a file that is not currently loaded or some such
        if bufexists(l:pos[0])
          call sign_unplace('MarkX', {'buffer' : l:pos[0], 'id' : l:mkCode})
        endif
      else
        call sign_unplace('MarkX', {'buffer' : bufnr(), 'id' : l:mkCode})
      endif
    endif
  else
    call s:PrintWarningMsg('MarkX: Cannot delete mark "'.a:mk.'" - invalid mark')
  endif
endfunction

" Unplace/remove multiple marks
"
" mk - A string indicating the marks to remove
"      Only marks 'a' to 'z', 'A' to 'Z' and ' ` < > [ ] may be specified
" Aglob - Only used for marks  'A' to 'Z'. If zero then a global mark
"         will only be deleted if it is associated with the local buffer.
"         Otherwise it shall always be deleted (regardless of the buffer it is
"         associated with)
"
function s:unplaceMany(mk, Aglob)
  let l:idx = 0
  while l:idx < len(a:mk)
    call s:unplaceMark(a:mk[l:idx], a:Aglob, 1)
    let l:idx += 1
  endwhile
endfunction

" Determine the next mark in the range 'a' to 'z' or 'A' to 'Z' to use for
" auto-selection and set it
"
" A - If zero then the selected mark will be in the range 'a' to 'z'. If
"     non-zero, the selected mark will be in the range 'A' to 'Z'
" ln - The line number to set the mark at. If 0 is specified then the mark
"      is placed at the cursor position. If ln > 0 then the mark is placed
"      at line ln, column 0
" force - If zero and no free marks are available then fail. If non-zero and no
"         free marks are available then re-allocate an existing/placed mark
"
" Returns mark name. '' is returned if 'forced' is false and no free marks are
" available
"
function s:placeNext(A, ln, force)
  let l:mkSet = ''

  let l:allMarks = (a:A) ? s:autoUMarks : s:autoLMarks

  if !len(l:allMarks)
    call s:PrintWarningMsg('MarkX: Cannot auto-place mark - no '.((a:A) ? "'A' to 'Z'"  : "'a' to 'z'").' marks specified in config')
  else
    let l:idxStart = (a:A) ? s:autoA : get(b:, 'MarkxAutoa', 0)
    let l:idx = l:idxStart
    let l:forced = 0

    " Current buffer number
    let l:bufn = bufnr()

    " Number of lines in buffer. Invalid marks will have line number in excess of this
    let l:nlines = line('$')

    " Search for next free (unplaced) mark and place it
    let l:stop = 0
    while !l:stop
      let l:pos = getpos("'".l:allMarks[l:idx])

      " To be eligible for being used, the mark must be either not placed, or be
      " invalid. Plus, if it's a global mark, it must be set in the current
      " buffer (if it's set at all)
      let l:eligible = (!l:pos[1] || (l:pos[1] > l:nlines)) && (!a:A || (l:pos[0] == l:bufn))
      if !l:eligible
        " Mark is defined/placed and not invalid - try next one
        let l:idx += 1
        if l:idx >= len(l:allMarks)
          let l:idx = 0
        endif

        if l:idx == l:idxStart
          " Have exhausted the search
          if a:force
            " Place the currently selected mark
            let l:mkSet = l:allMarks[l:idx]
            let l:forced = 1
          else
            call s:PrintWarningMsg('MarkX: Cannot auto-place mark - no free '.((a:A) ? "'A' to 'Z'"  : "'a' to 'z'").' marks left')
          endif
          let l:stop = 1
        endif
      else
        " Found a spare mark - place it
        let l:mkSet = l:allMarks[l:idx]
        let l:stop = 1
      endif
    endwhile

    if l:mkSet !=# ''
      " Set mark
      call s:placeMark(l:allMarks[l:idx], a:ln, 1)
      call s:PrintStatusMsg('MarkX: '.((l:forced) ? 'Moved' : 'Placed').' mark "'.(l:allMarks[l:idx]).'"')

      " Record next mark to set for next time this is called
      let l:idx += 1
      if l:idx >= len(l:allMarks)
        let l:idx = 0
      endif

      if a:A
        let s:autoA = l:idx
      else
        let b:MarkxAutoa = l:idx
      endif
    endif
  endif

  return l:mkSet
endfunction

" Reset the auto-placement mark to just after the one specified for
" the current buffer
"
" mk - The mark to search for. This must be 'a' to 'z', or 'A' to 'Z'
"
" Returns the mark immediately after 'mk'. If 'mk' cannot be found
" then '' is returned
"
function s:resetPlaceNext(mk)
  " Type of mark
  let l:type = s:mkType(a:mk)

  if (l:type ==# 'l') || (l:type ==# 'u')
    let l:allMarks = (l:type ==# 'l') ? s:autoUMarks : s:autoLMarks
    let l:idx = 0

    " Search for specified mark
    let l:stop = 0
    while !l:stop && (l:idx < len(l:allMarks))
      if a:mk == l:allMarks[l:idx]
        " Have located mark - reset auto mark to just after this
        let l:idx += 1
        if l:idx >= len(l:allMarks)
          let l:idx = 0
        endif
        if l:type ==# 'l'
          let b:MarkxAutoa = l:idx
        else
          let s:autoA = l:idx
        endif

        let l:stop = 1
      endif
      let l:idx += 1
    endwhile
  endif
endfunction

" Return visual mode ordinates
"
" rat - If '1' then the returned list elements are ordered so that line1 <=
"       line2 and col1 <= col2 (rationalised).
"       If '0' then the returned list elements are ordered so that the
"       line1/col1 represents the cursor position at the start of the selection
"       and line2/col2 represents the current cursor position at the end of the
"       selection (ie, the current cursor position)
"
" Returns
" A list in the order [line1, col1, line2, col2]. An empty list is returned on
" an error
"
function s:getVOrdinates(rat)
  " Get start and end line numbers of the visual selection
  let [l:l1, l:c1a, l:c1b] = getpos("'<")[1:3]
  let [l:l2, l:c2a, l:c2b] = getpos("'>")[1:3]
  let l:posn = []

  " The act of handling the key mapping will have caused visual mode to drop-out. Return to it
  exe 'normal! gv'

  " Get the logical column numbers of the start and end of the visual selection
  let l:c1 = col("'<")
  let l:c2 = col("'>")

  if a:rat == 1
    " Rationalise the returned list
    let l:posn = [l:l1, (l:c1 >= l:c2) ? l:c2 : l:c1, l:l2, (l:c1 >= l:c2) ? l:c1 : l:c2]
  else
    " Return list in an order showing the actual selection start and end points.
    " l1 will always be <= l2, so we need to check the current cursor position
    " to work out the order to return the list (to set cursor position at the end)
    let l:cursor = getpos('.')
    if ((l:cursor[1] == l:l1) && (l:cursor[2] == (l:c1a + l:c1b)))
      " Cursor is on line l1 (actually, position '<)
      let l:posn = [l:l2, l:c2, l:l1, l:c1]
    else
      " Cursor is on line l2 (actually position '>)
      let l:posn = [l:l1, l:c1, l:l2, l:c2]
    endif
  endif

  " Drop out of visual selection mode again
  exe "normal! \<esc>"

  return l:posn
endfunction

" Set a specific mark
function markx#Add(mk, ln)
  if a:mk !=# ""
    let l:fail = s:placeMark(a:mk, a:ln, 0)

    if (!l:fail && get(g:, 'MarkxSteponAuto', 0))
      call s:resetPlaceNext(a:mk)
    endif
  endif
endfunction

" Auto-select and place mark in the range 'a' to 'z'
function markx#Adda()
  call s:placeNext(0, 0, get(g:, 'MarkxAutoLForce', 0))
endfunction

" Auto-select and place mark in the range 'A' to 'Z'
function markx#AddA()
  call s:placeNext(1, 0, get(g:, 'MarkxAutoUForce', 0))
endfunction

" Set a mark while in visual selection mode
"
" type - '' = Place the mark 'mk'
"        'l' = auto-select and place mark in the range 'a' to 'z'
"        'u' = auto-select and place mark in the range 'A' to 'Z'
" mk - The mark to set if type is ''
"
function markx#Addv(type, mk)
  " Get visual selection details and cursor position
  let l:vsel = s:getVOrdinates(0)
  let l:curs = getcurpos()

  " Reposition cursor to where it is displayed in the window (this is often
  " wrong when the visual selection is active)
  call setpos('.', [0, l:vsel[2], l:vsel[3], l:curs[3]])

  " Place mark
  if a:type ==# ''
    call markx#Add(a:mk, 0)
  elseif a:type ==# 'l'
    call markx#Adda()
  else
    call markx#AddA()
  endif

  " Restore cursor so that visual selection can continue correctly, and re-enter
  " visual selection mode
  call setpos('.', l:curs)
  exe 'normal! gv'
endfunction

" Delete a mark
function markx#Del(mk)
  if a:mk !=# ""
    call s:unplaceMark(a:mk, 1, 0)
  endif
endfunction

" Delete all marks of a particular type. Only marks that are specified to
" have signs displayed for them are deleted
"
" type - Type of marks to delete -
"       'l' = All marks 'a' to 'z'
"       'u' = All marks 'A' to 'Z'
"       'p' = All marks ' ` < > [ ]
" auto - Optional. If non-zero then only the auto-placement marks of the
"        specific type are delete. This may only be used with types 'l'
"        and 'u'. If zero then all marks of 'type' are deleted
"
function markx#DelAll(type, auto = 0)
  let l:mk = ''
  if a:type ==# 'l'
    let l:mk = (a:auto) ? s:autoLMarks : s:userLMarks
  elseif a:type ==# 'u'
    let l:mk = (a:auto) ? s:autoUMarks : s:userUMarks
  elseif a:type ==# 'p'
    let l:mk = s:userPMarks
  endif

  if l:mk !=# ''
    " Get confirmation if configured
    if get(g:, 'MarkxConfirmDelAll', 0)
      " Get confirmation
      call inputsave()
      echohl Question
      let l:ans = input("MarkX: Delete all marks '".l:mk."' ? : ")
      echohl None
      call inputrestore()
      echo "\<cr>"
      if ((l:ans !=# 'y') && (l:ans !=# 'Y'))
        let l:mk = ''
      endif
    endif

    if l:mk !=# ''
      " Delete
      let l:Aglob = get(g:, 'MarkxDelAllUGlobal', 0)
      call s:unplaceMany(l:mk, l:Aglob)
      call s:PrintStatusMsg("MarkX: Deleted all marks '".l:mk."'".((a:type ==# 'u') ? ((l:Aglob) ? ' (globally)' : ' (from local buffer only)') : ''))
    endif
  endif
endfunction

" Refresh all marks/signs for current buffer
function markx#Refresh()
  let l:da = get(b:, 'MarkxDispAll', 0)
  if l:da
    call s:refreshSigns(s:getMarks(s:allGlobalMarks), s:getMarks(s:allLocalMarks))
  else
    call s:refreshSigns()
  endif
endfunction

" Refresh all marks/signs for all buffers displayed in current tab
function markx#RefreshAll()
  " It is not possible to break out of the 'command line' buffer if open, so
  " suppress the refresh if it is (avoids an error being output)
  if !((getbufvar(winbufnr(0), '&buftype') == 'nofile') && (bufname() == '[Command Line]'))
    " Save view before iterating through the windows
    let l:focuswin = winnr()
    let l:winview = winsaveview()

    " Pre-fetch this so that s:refreshSigns() does not have to do each time it is called below
    let l:globMarks = s:getMarks(s:userGlobMarks)

    " List of ALL global marks set (only needed if b:MarkxDispAll is set)
    let l:globMarksAll = []
    let l:globMarksAllSet = 0

    " A note of which buffers we have processed
    let l:done = {}

    " If 'secure' is set then the 'noautocmd' option when executing 'wincmd w'
    " will cause an error (I don't really understand this)
    const l:winCmdOpt = 'keepjumps '.((&secure) ? '' : 'noautocmd ')

    for l:winx in range(1, winnr('$'))
      exe l:winCmdOpt .l:winx.'wincmd w'

      let l:bufn = bufnr()
      if !has_key(l:done, l:bufn)
        " Refresh marks in buffer
        if get(b:, 'MarkxDispAll', 0)
          " Display all marks for this buffer
          if !l:globMarksAllSet
            let l:globMarksAll = s:getMarks(s:allGlobalMarks)
            let l:globMarksAllSet = 1
          endif

          call s:refreshSigns(l:globMarksAll, s:getMarks(s:allLocalMarks))
        else
          " Display only the marks specified in the config
          call s:refreshSigns(l:globMarks)
        endif

        let l:done[l:bufn] = 1
      endif
    endfor

    " Restore view
    exe l:winCmdOpt.l:focuswin.'wincmd w'
    call winrestview(l:winview)
  endif
endfunction

" Toggle 'display all signs for all marks'
function markx#ToggleShowAll()
  let l:da = get(b:, 'MarkxDispAll', 0)
  let b:MarkxDispAll = 1 - l:da
  call markx#Refresh()
  call s:PrintStatusMsg("MarkX: 'Display ALL marks for buffer' ".((b:MarkxDispAll) ? 'on' : 'off'))
endfunction

" Initialise auto-placement mark list(s)
"
" type - The type of list to initialise - 'l' or 'u'
" desc - The range of the list (for error output only)
" autoMarks - The list of auto marks (string)
" rec - The list of recorded marks from the main user marks list
"
" Return error status - 1 = error
"
function s:initAutoList(type, desc, autoMarks, rec)
  let l:err = 0

  " Duplicate mark name detection
  let l:autoDup = repeat([0], s:spanMarkNrs)

  " Check that auto marks are valid
  let l:idx = 0
  while !l:err && (l:idx < len(a:autoMarks))
    let l:mk = a:autoMarks[l:idx]
    let l:type = s:mkType(l:mk)

    if l:type == a:type
      let l:mkIdx = char2nr(l:mk) - s:firstMarkNr
      if l:autoDup[l:mkIdx]
        call s:PrintWarningMsg("MarkX: List of ".a:desc." auto marks includes a duplictate mark name; '".l:mk."'")
        call getchar()
        let l:err = 1
      elseif !a:rec[l:mkIdx]
        " Auto mark is not defined in user marks - error
        call s:PrintWarningMsg("MarkX: Auto ".a:desc." mark is outside of the managed range; '".l:mk."'")
        call getchar()
        let l:err = 1
      endif

      let l:autoDup[l:mkIdx] = 1
    else
      call s:PrintWarningMsg("MarkX: Auto ".a:desc." mark includes an invalid mark name; '".l:mk."'")
      call getchar()
      let l:err = 1
    endif

    let l:idx += 1
  endwhile

  return l:err
endfunction

" Initialisation
function markx#Init()
  let l:err = 0

  " Use user-selected marks to display, if specified. The default of
  " 'all marks' is used if the list if empty
  let l:allMarks = get(g:,'MarkxDisplayMarks', s:allLocalMarks.s:allGlobalMarks)
  if !len(l:allMarks)
    let l:allMarks = s:allLocalMarks.s:allGlobalMarks
  endif

  " Duplicate mark name and validity detection
  let l:rec = repeat([0], s:spanMarkNrs)

  " Split the list of all marks into their different types
  let l:idx = 0
  while !l:err && (l:idx < len(l:allMarks))
    let l:mk = l:allMarks[l:idx]
    let l:type = s:mkType(l:mk)

    if l:type !=# '-'
      " Check for duplicate
      let l:mkIdx = char2nr(l:mk) - s:firstMarkNr
      if l:rec[l:mkIdx]
        call s:PrintWarningMsg("MarkX: List of marks includes a duplictate mark name; '".l:mk."'")
        call getchar()
        let l:err = 1
      endif

      let l:rec[l:mkIdx] = 1
    endif

    if l:type ==# 'l'
      let s:userLMarks = s:userLMarks.l:mk
    elseif l:type ==# 'u'
      let s:userUMarks = s:userUMarks.l:mk
    elseif l:type ==# 'n'
      let s:userNMarks = s:userNMarks.l:mk
    elseif l:type ==# 'p'
      let s:userPMarks = s:userPMarks.l:mk
    elseif l:type ==# 'x'
      let s:userXMarks = s:userXMarks.l:mk
    else
      call s:PrintWarningMsg("MarkX: List of marks includes an invalid mark name; '".l:mk."'")
      call getchar()
      let l:err = 1
    endif

    let l:idx += 1
  endwhile

  " Lists of ALL local and ALL global marks the user is interested in
  let s:userLocalMarks = s:userLMarks.s:userPMarks.s:userXMarks
  let s:userGlobMarks = s:userUMarks.s:userNMarks

  if !l:err
    " Set up the lists of auto-selected marks
    let s:autoLMarks = get(g:, 'MarkxAutoLMarks', s:userLMarks)
    let s:autoUMarks = get(g:, 'MarkxAutoUMarks', s:userUMarks)

    let l:err = s:initAutoList('l', "'a' to 'z'", s:autoLMarks, l:rec)
    if !l:err
      let l:err = s:initAutoList('u', "'A' to 'Z'", s:autoUMarks, l:rec)
    endif
  endif
endfunction

" ------------------------------------------------------------------------------
" eof

