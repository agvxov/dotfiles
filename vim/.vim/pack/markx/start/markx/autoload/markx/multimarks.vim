" autoload/markx/multimarks.vim
"
" MarkX - Richard Bentley-Green
"
" Auto-placement of signs in the left margin, in response to creation and
" deletion of marks, plus some extra mark-placement functions
"
" This file contains definitions and functions that are only used when
" 'multimarks' is enabled
"
if exists('g:Markx_multimarks_loaded_autoload')
  finish
endif
const g:Markx_multimaarks_loaded_autoload = 1

" The list of marks to assess when considering 'multiple marks'. This is a
" string of mark names, BUT it only includes marks that are not already
" recorded by s:userLocalMarks or s:userGlobMarks in markx.vim
let s:multiMarks = ''

" ------------------------------------------------------------------------------
" Re-assess all marks and re-adjust any associated signs according to the
" 'multiple marks' configuration. This operates on the current buffer
"
" NOTE: This assumes that signs have already been created and placed for
"       all the marks in scope. THIS IS IMPORTANT!!
"
" bufn - Buffer to assess
" ln - Line number. If zero then the entrire buffer is re-assessed.
"      If > 0 then only marks placed on this line number are re-asessed
"
" Returns the 'multi' status last determined. This is likely only useful
" if a:ln > 0
"
function markx#multimarks#redoMultiMarks(bufn, ln)
  let l:multi = 0

  " We check two lists of marks for the specified line; a list of marks from
  " the 'standard' set and a list of additional marks from the 'multi marks'
  " set. ALL of the marks are eligible for 'multi mark' treatment; not
  " including the marks from the 'standard' set results in confusing and
  " inconsistent results

  let l:da = get(b:, 'MarkxDispAll', 0)
  " Get a list of all marks we may place signs for
  let l:allMarks = markx#getMarksByLine((get(b:, 'MarkxDispAll', 0)) ? '&a' : '&l' , a:bufn, a:ln)

  if len(l:allMarks)
    " Get a list of the marks to consider for 'multiple marks'
    let l:extraMultiMarks = markx#getMarksByLine(s:multiMarks, a:bufn, a:ln)

    " Check the marks on each line in-turn and re-assess their 'multiple
    " marks' representation
    let l:keys = keys(l:allMarks)
    for l:ln in l:keys
      " Determine if there are multiple marks on this line
      let l:marks = l:allMarks[l:ln]
      let l:multi = (len(l:marks) > 1) || has_key(l:extraMultiMarks, l:ln)

      " Set the 'multiple marks' status for each mark on the line
      let l:idx = 0
      while l:idx < len(l:marks)
        let l:mk = l:marks[l:idx]
        call markx#makeSign(l:mk, markx#mkType(l:mk), l:multi, a:bufn)
        let l:idx += 1
      endwhile
    endfor
  endif

  return l:multi
endfunction

" Remove all signs from the buffer specified by '<abuf>'.
" This is only ever called if 'multi marks' representation is enabled
"
" Note that this function could do nothing if b:MarksDisp == '' but
" as it's only called when the buffer is removed from view, it's
" probably safer to always run it anyway
function markx#multimarks#Remove()
  let l:bufn = str2nr(expand('<abuf>'))
  call markx#delete#deleteSigns(l:bufn)
endfunction

" Remove all signs from all buffers. Technically, this is only those
" displayed in the current tab but as this is only ever called if
" 'multi marks' representation is enabled, it amounts to the same thing
function markx#multimarks#RemoveAll()
  call markx#delete#deleteSigns(0)
endfunction

" Initialisation - multimarks-specific
"
" rec - The list of recorded marks from the main user marks list
"
" Return error status - 1 = error
"
function markx#multimarks#initMultimarksList(rec)
  " Process the user-supplied list of marks to assess when considering
  " 'multiple marks' on a single line
  let l:multiMarks = get(g:, 'MarkxMultiMarks', '')

  if len(l:multiMarks)
    " List of mark names of interest
    let l:mrec = repeat([0], markx#spanMarkNrs())

    " Record the type of each of the supplied mark names
    const l:firstMarkNr = markx#firstMarkNr()
    let l:idx = 0
    while !l:err && (l:idx < len(l:multiMarks))
      let l:mk = l:multiMarks[l:idx]
      let l:type = markx#mkType(l:mk)

      if l:type !=# '-'
        " Check for duplicate
        let l:mkIdx = char2nr(l:mk) - l:firstMarkNr
        if l:mrec[l:mkIdx]
          let l:err = markx#listCheckError('g:MarkxMultiMarks', 'a duplicate mark name', l:mk)
        endif

        let l:mrec[l:mkIdx] = 1

        if !a:rec[l:mkIdx]
          " Mark is not in the 'user' list - make a note of it
          let s:multiMarks .= l:mk
        endif
      else
        let l:err = markx#listCheckError('g:MarkxMultiMarks', 'an invalid mark name', l:mk)
      endif

      let l:idx += 1
    endwhile
  endif
endfunction

" ------------------------------------------------------------------------------
" eof

