" autoload/markx.vim
"
" MarkX - Richard Bentley-Green, 05/08/2026
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
" - Local marks include 'a' to 'z', and the 13 punctuation marks ' < > [ ] ` " ( ) . ^ { }
" - Global marks include 'A' to 'Z', '0' to '9'
"
" The 'X' and 'N' marks cannot be explicitly set by the user; they are controlled by vim
const s:allL = 'abcdefghijklmnopqrstuvwxyz'
const s:allP = "'<>[]`"
const s:allX = "\"().^{}"
const s:allU = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
const s:allN = '0123456789'

const s:allLocalMarks = s:allL.s:allP.s:allX
const s:allGlobalMarks = s:allU.s:allN

" A lookup table to determine the type of a mark (see the function s:mkType() for details)
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
highlight default MarkXM ctermfg=255 ctermbg=0 cterm=bold guifg=#eeeeee guibg=#000000 gui=bold

" Sign priorities. The higher the value, the higher the priority (vim default is 10)
const s:sPriorL = get(g:, 'MarkxPriorL', 10)
const s:sPriorP = get(g:, 'MarkxPriorP', 10)
const s:sPriorU = get(g:, 'MarkxPriorU', 10)
const s:sPriorN = get(g:, 'MarkxPriorN', 10)

" The ASCII code for the first possible mark, and the span of all marks (NOT the
" same as the total number of marks)
const s:firstMarkNr = char2nr('"')
const s:spanMarkNrs = (char2nr('}') - char2nr('"')) + 1

" Default mark signs display state for each buffer
" '' = Do not display any signs at all (MarkX effectively does nothing).
" 's' = Display signs for the 'standard' marks, according to the `g:MarkxDisplayMarks` setting
" 'a' = Display signs for all marks
const s:dispDefault = get(g:, 'MarksDisplayDefault', '')

" An optional character to place after the sign name. This may be an empty
" string or a single character. If defined, a character such as '>' or ':'
" is often used
const s:mktrail = get(g:, 'MarkxSignTrail', '')

" Description of how to display the MarkX signs when multiple signs are positioned
" at the same line
"
" The following options are available;-
" ''  = Disables distinguishing when multiple marks are set on the same line
" 'H' = When multiple signs are set on the same line then if the sign that is
"       visible happens to be one set by MarkX then display one of the marks'
"       signs in the colour specified by the colour group 'MarkXM'
" '+' = When multiple signs are set on the same line then if the sign that is
"       visible happens to be one set by MarkX then display one of the marks'
"       signs in its standard colour but with a trailing additional character
"       (as specified by 'g:MarkxMultiTrail'). Note that in this case, any
"       additional character specified by 'g:MarkxSignTrail' is not displayed
"       when multiple marks are set on the same line
" 'M' = Combines options 'H' and '+'
const s:multiMarksCfg = get(g:, 'MarkxMultiCfg', '+')

" If 'g:MarkxMultiCfg' is set to '+' or 'M' (see previous) then this is the
" additional character to use
const s:multiMarksPlusChar = get(g:, 'MarkxMultiTrail', '+')

" Pre-calculated constants relating to handling multiple signs on a line
const s:msPlaceTrail = (s:multiMarksCfg !=# 'H') ? s:multiMarksPlusChar : s:mktrail

" The group name to use for all MarkX signs
const s:signGroup = 'MarkX'

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
" Return the first mark number
function markx#firstMarkNr()
  return s:firstMarkNr
endfunction

" Return the mark number span
function markx#spanMarkNrs()
  return s:spanMarkNrs
endfunction

" Return the sign group name
function markx#signGroup()
  return s:signGroup
endfunction

" Determine the type of mark
"
" mk - The mark name to assess
"
" Returns the type of mark;-
" '-' - Not a valid mark name
" 'l' - The mark is in the range 'a' to 'z'
" 'u' - The mark is in the range 'A' to 'Z'
" 'p' - The mark is one of ' ` < > [ ]
" 'x' - The mark is one of " ( ) . ^ { } (these marks cannot be explicitly set)
" 'n' - The mark is in the range '0' to '9' (these marks cannot be explicitly set)
"
function s:mkType(mk)
  let l:type = '-'
  let l:mkn = char2nr(a:mk) - s:firstMarkNr

  if (l:mkn >= 0) && (l:mkn < s:spanMarkNrs)
    let l:type = s:mkTypes[l:mkn]
  endif

  return l:type
endfunction

" A wrapper for the above function, used by the multimarks module
function markx#mkType(mk)
  return s:mkType(a:mk)
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
" Returns a list of active marks. Each list element is itself a 3 element list;
" [0] = a single character (the mark's name)
" [1] = the line number the mark is attached to
" [2] = the buffer number that the mark is assigned to (this only applies
"       if the mark is a global one; zero shall be returned for local marks)
"
function s:getMarks(mk)
  " Index into 'mk' string
  let l:mkx = 0

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

" Return a list of currently active marks (whether local or global) for
" the current buffer
"
" The NOTE described above for the function s:getMarks() also applies here
"
" mk - A string specifying a list of marks to consider and return status'
"      for
" bufn - The buffer to retrive marks for. This should always be the current
"        buffer
" ln - Line number. If zero then all marks specified by 'mk' are
"      (potentially) returned. If > 0 then only marks placed on this line
"      number are defined. Global marks are only returned if they too are
"      placed in the current buffer on the specified line number. In the
"      latter case (ln > 0), the returned hash shall contain (at most) a
"      single key which is the line number requested
"
" Returns a hash of strings, each string being a list of active marks. The
" hash is keyed by line number
"
function s:getMarksByLine(mk, bufn, ln)
  " Index into 'mk' string
  let l:mkx = 0

  " Hash of mark names that are set
  let l:currMarks = {}

  while l:mkx < len(a:mk)
    let l:pos = getpos("'".a:mk[l:mkx])
    if l:pos[1]
      " Mark is set (though may be invalid)
      " If a:ln is specified then only record global marks if it's local to the buffer
      let l:ln = l:pos[1]
      if (!a:ln || (l:ln == a:ln)) && (!l:pos[0] || (l:pos[0] == a:bufn))
        " Record this mark
        let l:entry = [a:mk[l:mkx]]
        if has_key(l:currMarks, l:ln)
          let l:currMarks[l:ln] .= a:mk[l:mkx]
        else
          let l:currMarks[l:ln] = a:mk[l:mkx]
        endif
      endif
    endif

    let l:mkx += 1
  endwhile

  return l:currMarks
endfunction

" A special wrapper around the above function used by the multimarks functions
function markx#getMarksByLine(mk, bufn, ln)
  let l:marks = s:getMarksByLine((a:mk ==# '&a') ? s:allLocalMarks.s:allGlobalMarks : ((a:mk ==# '&l') ? s:userLocalMarks.s:userGlobMarks : a:mk), a:bufn, a:ln)

  return l:marks
endfunction

" Return the colour to use for the specified mark type
"
" type - The type of mark, as returned by mkType()
"
function s:signColour(type)
  let l:colour = 'MarkXP'
  if a:type ==# 'l'
    let l:colour = 'MarkXL'
  elseif a:type ==# 'u'
    let l:colour = 'MarkXU'
  elseif a:type ==# 'n'
    let l:colour = 'MarkXN'
  endif

  return l:colour
endfunction

" Return the name of a sign definition, based on its type and 'miltiple marks'
" configuration
"
" If 'multiple marks' highligting is enabled then every sign related to a mark
" that is local to a buffer (ie, 'a' to 'z' and all 13 punctuation marks) must
" be uniquely defined (ie, the same sign definition cannot be shared between
" buffers). To facilitate this, we assign each a unique id. This is defined as
" two fields; the buffer number and the ASCII number of the mark name
"
" mk - The mark name to create the sign for
" type - The type of mark, as returned by mkType()
" bufn - The buffer number that this sign is being assined to. This is only
"        used if 'multiple marks' is set and the sign is 'local'
"
" Returns the constructed name
"
function s:makeSignName(mk, type, bufn)
  let l:name = 'MarkX'.(((s:multiMarksCfg !=# '') && ((a:type !=# 'u') && (a:type !=# 'n'))) ? a:bufn.'_' : '').char2nr(a:mk)
  return l:name
endfunction

" Define a sign - if the sign already exists then it is just updated
"
" mk - The mark name to create the sign for
" type - The type of mark, as returned by mkType(). This is used to set the
"        colour of the sign. The type is assumed to be valid
" multi - 0 = use standard sign representation. 1 = overrides 'type' and uses
"         the 'multiple marks' setting to determine the sign representation
" bufn - The buffer number that this sign is being assined to. This is only
"        used if 'multiple marks' is enabled and the sign is 'local'
"
" Returns the name assigned to the sign
"
function markx#makeSign(mk, type, multi, bufn)
  let l:name = s:makeSignName(a:mk, a:type, a:bufn)
  if a:multi
    let l:colour = (s:multiMarksCfg !=# '+') ? 'MarkXM' : s:signColour(a:type)
    call sign_define(l:name, {'text' : a:mk.s:msPlaceTrail, 'texthl' : l:colour})
  else
    call sign_define(l:name, {'text' : a:mk.s:mktrail, 'texthl' : s:signColour(a:type)})
  endif

  return l:name
endfunction

" Refresh all signs in the current buffer
"
" globMarks - Optional. If specified, then this is the list of global marks to consider
" localMarks - Optional. If specified then this is the list of local marks to consider
"
function s:refreshSigns(globMarks = s:getMarks(s:userGlobMarks), localMarks = s:getMarks(s:userLocalMarks))
  " The buffer number associated with the current window
  let l:bufn = bufnr()

  " Get list of placed signs in the specified buffer
  let l:splacedList = sign_getplaced(l:bufn, {'group' : s:signGroup})[0]['signs']
  let l:splaced = repeat([0], s:spanMarkNrs)
  let l:splacedCount = 0

  " Extract Id and line number for each defined sign
  let l:idx = 0
  while l:idx < len(l:splacedList)
    let l:id = l:splacedList[l:idx]['id'] - s:firstMarkNr
    if (l:id >= 0) && (l:id < s:spanMarkNrs)
      " This is a sign we may be interested in - record its line number
      let l:splaced[l:id] = l:splacedList[l:idx]['lnum']
      let l:splacedCount += 1
    endif
    let l:idx += 1
  endwhile

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
          call sign_unplace(s:signGroup, {'buffer' : l:bufn, 'id' : l:mkCode})
          call sign_place(l:mkCode, s:signGroup, s:makeSignName(l:mkName, s:mkType(l:mkName), l:bufn), l:bufn, {'lnum' : l:mk[l:mkx][1], 'priority' : l:sPrior})
        endif

        " Mark sign as 'processed'
        let l:splaced[l:idx] = 0
        let l:splacedCount -= 1
      elseif !l:pass || (l:mk[l:mkx][2] == l:bufn)
        " On second pass, the buffer number of the 'global' mark must match the
        " specified buffer in order to be considered

        " Sign is not placed for this mark - place it
        let l:name = markx#makeSign(l:mkName, s:mkType(l:mkName), 0, l:bufn)
        call sign_place(l:mkCode, s:signGroup, l:name, l:bufn, {'lnum' : l:mk[l:mkx][1], 'priority' : l:sPrior})
      endif
      let l:mkx += 1
    endwhile

    " Prepare for second pass - get list of active global marks
    let l:mk = a:globMarks

    let l:pass += 1
  endwhile

  " Remove any signs that do not have associated marks
  let l:idx = 0
  while l:splacedCount && (l:idx < s:spanMarkNrs)
    if l:splaced[l:idx]
      " Sign is placed - remove it
      call sign_unplace(s:signGroup, {'buffer' : l:bufn, 'id' : l:idx + s:firstMarkNr})

      " Mark sign as 'processed'
      let l:splacedCount -= 1
    endif
    let l:idx += 1
  endwhile

  if s:multiMarksCfg !=# ''
    call markx#multimarks#redoMultiMarks(l:bufn, 0)
  endif
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
        call sign_unplace(s:signGroup, {'buffer' : l:pos[0], 'id' : l:mkCode})
      endif

      " Place or move the marker. Note that this uses the command line 'mark'
      " commands rather then setpos() to ensure the behaviour is consistant with
      " the mapping that this function is invoked from
      if a:ln
        " Place at specified line, column 0
        exe l:ln.'mark '.a:mk
      else
        " Place at cursor position
        exe 'normal! m'.a:mk
      endif

      if s:multiMarksCfg !=# ''
        " Clean-up old buffer/position
        call markx#multimarks#redoMultiMarks(l:pos[0], l:pos[1])
      endif

      if l:signed && (get(b:, 'MarkxDisp', s:dispDefault) !=# '')
        " The priority of the associated sign
        let l:sPrior = s:sPriorP
        if l:type ==# 'l'
          let l:sPrior = s:sPriorL
        elseif l:type ==# 'u'
          let l:sPrior = s:sPriorU
        endif

        " Adjust the associated sign
        let l:sign = sign_getplaced(l:bufn, {'group' : s:signGroup, 'id' : l:mkCode})[0]['signs']
        if len(l:sign)
          " Sign is placed for this mark
          "
          " Note that if we are moving the sign from one buffer to another then
          " l:sign will be empty (because the above call to sign_getplaced() specifies
          " the new (target) buffer. Hence we will never get to this point. It is for
          " this reason that any difference in the buffer id does not need to be
          " checked here (it will never be different); only the line number
          if l:sign[0]['lnum'] != l:ln
            " Sign line number doesn't match mark's line number - move the sign
            call sign_unplace(s:signGroup, {'buffer' : l:bufn, 'id' : l:mkCode})
            if s:multiMarksCfg !=# ''
              " Clean-up
              call markx#multimarks#redoMultiMarks(l:bufn, l:sign[0]['lnum'])
            endif

            call sign_place(l:mkCode, s:signGroup, l:sign[0]['name'], l:bufn, {'lnum' : l:ln, 'priority' : l:sPrior})
            if s:multiMarksCfg !=# ''
              call markx#multimarks#redoMultiMarks(l:bufn, l:ln)
            endif
          endif
        else
          " Sign is not placed for this mark - place it
          let l:name = markx#makeSign(a:mk, l:type, 0, l:bufn)
          call sign_place(l:mkCode, s:signGroup, l:name, l:bufn, {'lnum' : l:ln, 'priority' : l:sPrior})

          if s:multiMarksCfg !=# ''
            call markx#multimarks#redoMultiMarks(l:bufn, l:ln)
          endif
        endif
      endif

      let l:fail = 0
    endif
  else
    call s:PrintWarningMsg('MarkX: Cannot place mark "'.a:mk.'" - invalid mark')
  endif

  return l:fail
endfunction

" Unplace a sign, and delete its definition if it's local and 'multi-marks' is
" in operation
"
" bufn - The buffer to delete the sign from
" mk - The name of the mark that the sign is associated with
"
function markx#unplaceSign(bufn, mk)
  " The supplied buffer may not actually exist
  if bufexists(a:bufn)
    " The mark name converted to its ASCII code equiv
    let l:mkCode = char2nr(a:mk)

    let l:type = s:mkType(a:mk)
    if (l:type !=# 'u') && (l:type !=# 'n') && (s:multiMarksCfg !=# '')
      " Local mark and multi-marks is in operation - delete the sign definition
      let l:sign = sign_getplaced(a:bufn, {'group' : s:signGroup, 'id' : l:mkCode})[0]['signs']

      " Should always exist but no harm in checking
      if len(l:sign)
        let l:signName = l:sign[0]['name']
        if len(sign_getdefined(l:signName))
          call sign_undefine(l:signName)
        endif
      endif
    endif

    " Unplace the sign for the mark (if it's placed). The sign may be in the
    " current buffer or (if the associated mark is global) in some other buffer
    call sign_unplace(s:signGroup, {'buffer' : a:bufn, 'id' : l:mkCode})
  endif
endfunction

" Unplace/remove a mark and its associated sign.
" If the mark is a global type then it may be defined in (and removed
" from) some buffer other than the current one
"
" Only marks 'a' to 'z', 'A' to 'Z' and ' ` < > [ ] may be specified
"
" mk - The mark name to remove
" Aglob - Only used for marks  'A' to 'Z'. If zero then a global mark
"         will only be deleted if it is associated with the local buffer.
"         If non-zero, the mark shall always be deleted (regardless of the
"         buffer it is associated with)
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

        if s:multiMarksCfg !=# ''
          " Clean-up
          call markx#multimarks#redoMultiMarks(bufnr(), l:pos[1])
        endif
      endif

      call markx#unplaceSign((l:type ==# 'u') ? l:pos[0] : bufnr(), a:mk)
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
" test - Perform a dry run. No mark is moved/placed. Only print the action that
"        would be taken if not a dry run
"
" Returns mark name. '' is returned if 'forced' is false and no free marks are
" available
"
function s:placeNext(A, ln, force, test)
  let l:mkSet = ''

  let l:allMarks = (a:A) ? s:autoUMarks : s:autoLMarks
  let l:testId = (a:test) ? ' next' : ''

  if !len(l:allMarks)
    call s:PrintWarningMsg('MarkX: Cannot auto-place'.l:testId.' mark - no '.((a:A) ? "'A' to 'Z'"  : "'a' to 'z'").' marks specified in config')
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
      let l:eligible = (!l:pos[1]) || ((l:pos[1] > l:nlines) && (!a:A || (l:pos[0] == l:bufn)))
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
            call s:PrintWarningMsg('MarkX: Cannot auto-place'.l:testId.' mark - no free '.((a:A) ? "'A' to 'Z'"  : "'a' to 'z'").' marks left')
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
      if a:test
        " Dry run
        call s:PrintStatusMsg('MarkX: Next mark to be placed will be "'.(l:allMarks[l:idx]).'"'.((l:forced) ? ' (moved from curr. location)' : ''))
      else
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
"
" test - Perform a dry run. No mark is moved/placed. Only print the action that
"        would be taken if not a dry run
"
function markx#Adda(test)
  call s:placeNext(0, 0, get(g:, 'MarkxAutoLForce', 0), a:test)
endfunction

" Auto-select and place mark in the range 'A' to 'Z'
function markx#AddA(test)
  call s:placeNext(1, 0, get(g:, 'MarkxAutoUForce', 0), a:test)
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
    call markx#Adda(0)
  else
    call markx#AddA(0)
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
  let l:disp = get(b:, 'MarkxDisp', s:dispDefault)
  if l:disp !=# ''
    if l:disp ==# 'a'
      call s:refreshSigns(s:getMarks(s:allGlobalMarks), s:getMarks(s:allLocalMarks))
    else
      call s:refreshSigns()
    endif
  endif
endfunction

" Refresh all marks/signs for the current window's buffer
"
" allGlobMarks - Ref's to the 'all global' and 'user global' marks
" userGlobMarks  to be passed on to s:refreshSigns()
"
function s:refreshWin(allGlobMarks, userGlobMarks)
  " Refresh marks in buffer
  let l:disp = get(b:, 'MarkxDisp', s:dispDefault)
  if l:disp !=# ''
    let l:localMarks = s:getMarks((l:disp ==# 'a') ? s:allLocalMarks : s:userLocalMarks)
    call s:refreshSigns((l:disp ==# 'a') ? a:allGlobMarks : a:userGlobMarks, l:localMarks)
  endif
endfunction

" Refresh all marks/signs for all buffers displayed in current tab
function markx#RefreshAll()
  " It is not possible to break out of the 'command line' buffer if open, so
  " suppress the refresh if it is (avoids an error being output).
  " Use the info '.command' field if available (newer versions of vim/nvim)
  " else fall back to the 'old' way of checking this
  let l:buffInfo = getbufinfo(winbufnr(0))
  let l:isCmdBuff = (exists('l:buffInfo[0].command')) ? l:buffInfo[0].command : (getbufvar(winbufnr(0), '&buftype') == 'nofile') && (bufname() == '[Command Line]')

  if !l:isCmdBuff
    " Pre-fetch these so that s:refreshSigns() does not have to, each time it is called below
    let l:allGlobMarks = s:getMarks(s:allGlobalMarks)
    let l:userGlobMarks = s:getMarks(s:userGlobMarks)

    " A note of which buffers we have processed
    let l:done = {}

    " Stop autocmds getting in the way
    let l:events=&eventignore
    set eventignore=WinEnter,WinLeave

    " Refresh each window
    for l:winx in range(1, winnr('$'))
      let l:bufn = winbufnr(l:winx)
      if !has_key(l:done, l:bufn)
        call win_execute(win_getid(l:winx), 'call s:refreshWin(l:allGlobMarks, l:userGlobMarks)')
        let l:done[l:bufn] = 1
      endif
    endfor

    exe 'set eventignore='.l:events
  endif
endfunction

" Set which signs (if any) to display. Operates on current buffer
"
" disp - '' = Do not display any signs
"        'n' = Display 'normal' (as specified by user) signs
"        'a' = Display all signs
"
function markx#Show(disp)
  let b:MarkxDisp = a:disp
  if a:disp !=# ''
    call markx#Refresh()
    if a:disp ==# 'a'
      call s:PrintStatusMsg("MarkX: 'Display ALL marks for buffer' on")
    else
      call s:PrintStatusMsg('MarkX: Display on')
    endif
  else
    call markx#delete#deleteSigns(bufnr())

    call s:PrintStatusMsg('MarkX: Display off')
  endif
endfunction

" Toggle 'display all signs for all marks'
function markx#ToggleShowAll()
  let l:disp = get(b:, 'MarkxDisp', s:dispDefault)
  let b:MarkxDisp = (l:disp ==# 'a') ? 's' : 'a'
  call markx#Refresh()
  call s:PrintStatusMsg("MarkX: 'Display ALL marks for buffer' ".((b:MarkxDisp ==# 'a') ? 'on' : 'off'))
endfunction

" Returns the total length of the text required to print the marks for the
" specified line
"
" marks - A list of all marks to consider
" types - A string of the mark types to consider
" ln - The line number to check for in the 'marks' list
"
" The length of the string that will be required
"
function s:calcMarksPrintLen(marks, types, ln)
  let l:len = 0

  let l:typex = 0
  while l:typex < len(a:types)
    if has_key(a:marks[a:types[l:typex]][0], a:ln)
      let l:count = len(a:marks[a:types[l:typex]][0][a:ln])
      if l:count
        let l:len += l:count + 1
      endif
    endif

    let l:typex += 1
  endwhile

  return ((l:len) ? l:len - 1 : 0)
endfunction

" Print a line of text that includes the line number and one batch of marks (by
" type) - Helper function for the following print operation
"
" marks - A list of marks of a specific type
" ln - The line number to check for in the 'marks' list
" colour - The colour to use to display the marks (depends on type)
" placed - true = marks have already been printed for this line. false
"          otherwise
"
" Returns true if 'marks' were printed or a:marks was true
"
function s:printMarks(marks, ln, colour, placed)
  let l:placed = a:placed
  if has_key(a:marks, a:ln)
    if !l:placed
      echo a:ln.' :'
      let l:placed = 1
    endif

    echon ' '
    exe 'echohl '.a:colour
    echon a:marks[a:ln]
    echohl None
  endif

  return l:placed
endfunction

" Print a list of marks set in the current buffer
"
" ln - Line number. If zero then marks are printed for the entire file
"      If > 0 then only marks on this line number are printed
"      If < 0 then only marks on the current line number are printed
function markx#PrintMarks(ln)
  let l:bufn = bufnr()
  const l:ln = (a:ln >= 0) ? a:ln : line('.')

  if get(b:, 'MarkxDisp', s:dispDefault) !=# ''
    " Make sure the displayed signs match the placed marks
    call markx#Refresh()
    redraw
  endif

  " Get print option
  let l:types = get(g:, 'MarkxPrintTypes', 'lupxn')

  " Get a list of all the different types of mark
  let l:marks = {}
  let l:marks['l'] = [s:getMarksByLine(s:allL, l:bufn, l:ln), 'MarkXL']
  let l:marks['p'] = [s:getMarksByLine(s:allP, l:bufn, l:ln), 'MarkXP']
  let l:marks['x'] = [s:getMarksByLine(s:allX, l:bufn, l:ln), 'MarkXP']
  let l:marks['u'] = [s:getMarksByLine(s:allU, l:bufn, l:ln), 'MarkXU']
  let l:marks['n'] = [s:getMarksByLine(s:allN, l:bufn, l:ln), 'MarkXN']

  " Construct a list of line numbers of interest
  let l:typex = 0
  let l:lnums = []
  while l:typex < len(l:types)
    let l:lnums += keys(l:marks[l:types[l:typex]][0])
    let l:typex += 1
  endwhile

  call sort(l:lnums, 'N')
  call uniq(l:lnums, 'N')

  if len(l:lnums)
    " Print details of the marks
    echohl StatusMsg | echo 'Marks placed '.((l:ln) ? 'on line;-' : 'in buffer;-') | echohl None

    " Calculate the length of the marks text string for each line and the
    " overall longest length. We only need this if printing multiple lines
    let l:maxlen = 1
    let l:llens = {}

    if !a:ln
      let l:nidx = 0
      while l:nidx < len(l:lnums)
        let l:lnum = l:lnums[l:nidx]
        let l:llen = s:calcMarksPrintLen(l:marks, l:types, l:lnum)
        if l:llen
          let l:llens[l:lnum] = l:llen
          if l:maxlen < l:llen
            let l:maxlen = l:llen
          endif
        endif

        let l:nidx += 1
      endwhile
    endif

    " Print the marks
    let l:padding = repeat(' ', l:maxlen)
    let l:bufflen = line('$')

    let l:nidx = 0
    while l:nidx < len(l:lnums)
      let l:lnum = l:lnums[l:nidx]

      let l:placed = 0
      let l:typex = 0
      while l:typex < len(l:types)
        let l:placed = s:printMarks(l:marks[l:types[l:typex]][0], l:lnum, l:marks[l:types[l:typex]][1], l:placed)
        let l:typex += 1
      endwhile

      " Print text from the line (skip if the window is very narrow)
      if l:maxlen < (&columns - 16)
        let l:text = ''
        if (l:lnum > l:bufflen)
          " Mark is placed on a line beyond the end of the file
          let l:text = '>>> BEYOND END OF FILE <<<"'
        else
          let l:text = substitute(getbufline(l:bufn, l:lnum)[0], '^\_s*\(.\{-}\)\_s*$', '\1', '')
        endif

        if l:text !=# ''
          " Padding between mark names and this text
          let l:pad = (a:ln) ? 1 : l:maxlen - l:llens[l:lnum]

          " Truncate text so it doesn't wrap on the command line
          let l:width = &columns - l:maxlen - 10
          echon l:padding[0:l:pad].": ".l:text[0:l:width]
        endif
      endif

      let l:nidx += 1
    endwhile
  else
    echohl StatusMsg | echo 'No marks placed '.((l:ln) ? 'on line '.l:ln : 'in buffer') | echohl None
  endif
endfunction

" An error reporting function used by the following initialisation functions
function markx#listCheckError(setting, err, mk)
  call s:PrintWarningMsg("MarkX: List of marks defined by '".a:setting."' includes ".a:err."; '".a:mk."'")
  call getchar()
  return 1
endfunction

" Initialise auto-placement mark list(s)
"
" type - The type of list to initialise - 'l' or 'u'
" setting - The setting that defines the supplied list (for error output only)
" autoMarks - The list of auto marks (string)
" rec - The list of recorded marks from the main user marks list
"
" Return error status - 1 = error
"
function s:initAutoList(type, setting, autoMarks, rec)
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
        let l:err = call markx#listCheckError(a:setting, 'a duplicate mark name', l:mk)
      elseif !a:rec[l:mkIdx]
        " Auto mark is not defined in user marks - error
        let l:err = call markx#listCheckError(a:setting, 'a mark name outside of the managed range', l:mk)
      endif

      let l:autoDup[l:mkIdx] = 1
    else
      let l:err = markx#listCheckError(a:setting, 'an invalid mark name', l:mk)
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
  let l:marksList = get(g:,'MarkxDisplayMarks', s:allLocalMarks.s:allGlobalMarks)
  if !len(l:marksList)
    let l:marksList = s:allLocalMarks.s:allGlobalMarks
  endif

  " Duplicate mark name and validity detection
  let l:rec = repeat([0], s:spanMarkNrs)

  " Split the list of all marks into their different types
  let l:idx = 0
  while !l:err && (l:idx < len(l:marksList))
    let l:mk = l:marksList[l:idx]
    let l:type = s:mkType(l:mk)

    if l:type !=# '-'
      " Check for duplicate
      let l:mkIdx = char2nr(l:mk) - s:firstMarkNr
      if l:rec[l:mkIdx]
        let l:err = markx#listCheckError('g:MarkxDisplayMarks', 'a duplicate mark name', l:mk)
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
      let l:err = markx#listCheckError('g:MarkxDisplayMarks', 'an invalid mark name', l:mk)
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

    let l:err = s:initAutoList('l', 'g:MarkxAutoLMarks', s:autoLMarks, l:rec)
    if !l:err
      let l:err = s:initAutoList('u', 'g:MarkxAutoUMarks', s:autoUMarks, l:rec)
    endif
  endif

  if !l:err && (s:multiMarksCfg !=# '')
    call markx#multimarks#initMultimarksList(l:rec)
  endif
endfunction

" ------------------------------------------------------------------------------
" eof

