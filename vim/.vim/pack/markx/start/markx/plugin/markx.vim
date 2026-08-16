" plugin/markx.vim
"
" MarkX - Richard Bentley-Green, 05/08/2026
"
" Auto-placement of signs in the left margin, in response to creation and
" deletion of marks, plus some extra mark-placement functions
"
if exists('g:Markx_loaded')
  finish
endif
const g:Markx_loaded = 1

" ----------------------------------
" This is a non-standard colour
highlight default link StatusMsg Normal

" ----------------------------------
" Set a specific mark
nnoremap <silent> <plug>(MarkXAdd) :call markx#Add(nr2char(getchar()), 0)<cr>
vnoremap <silent> <plug>(MarkXAdd) :<C-u>call markx#Addv('', nr2char(getchar()))<cr>

" Auto-select and set mark
nnoremap <silent> <plug>(MarkXAdda) :call markx#Adda(0)<cr>
vnoremap <silent> <plug>(MarkXAdda) :<C-u>call markx#Addv('l', '')<cr>
nnoremap <silent> <plug>(MarkXAddA) :call markx#AddA(0)<cr>
vnoremap <silent> <plug>(MarkXAddA) :<C-u>call markx#Addv('u', '')<cr>

" Auto-select dry run
nnoremap <silent> <plug>(MarkXAddaTest) :call markx#Adda(1)<cr>
nnoremap <silent> <plug>(MarkXAddATest) :call markx#AddA(1)<cr>

" Delete a mark
nnoremap <silent> <plug>(MarkXDel) :call markx#Del(nr2char(getchar()))<cr>

" Delete all marks
nnoremap <silent> <plug>(MarkXDelAllL) :call markx#DelAll('l')<cr>
nnoremap <silent> <plug>(MarkXDelAllU) :call markx#DelAll('u')<cr>
nnoremap <silent> <plug>(MarkXDelAllP) :call markx#DelAll('p')<cr>

" Delete all auto-placed marks
nnoremap <silent> <plug>(MarkXDelAllAutoL) :call markx#DelAll('l', 1)<cr>
nnoremap <silent> <plug>(MarkXDelAllAutoU) :call markx#DelAll('u', 1)<cr>

" Print a list of the marks set on the current line or the whole buffer
nnoremap <silent> <plug>(MarkXPrintMarksOnLine) :call markx#PrintMarks(-1)<cr>
nnoremap <silent> <plug>(MarkXPrintMarksInBuffer) :call markx#PrintMarks(0)<cr>

" Refresh all marks/signs
nnoremap <silent> <plug>(MarkXRefresh) :call markx#Refresh()<cr>
nnoremap <silent> <plug>(MarkXRefreshAll) :call markx#RefreshAll()<cr>

" Display no marks, standard marks, or all marks
nnoremap <silent> <plug>(MarkXShowNone) :call markx#Show('')<cr>
nnoremap <silent> <plug>(MarkXShowStd) :call markx#Show('s')<cr>
nnoremap <silent> <plug>(MarkXShowAll) :call markx#Show('a')<cr>

" Toggle 'display signs for ALL marks in current buffer'
nnoremap <silent> <plug>(MarkXToggleShowAll) :call markx#ToggleShowAll()<cr>

" ------------------------------------------------------------------------------
" Commands (for details of global options used here, see README)

" Toggle the g:MarkxAutoLForce configuration setting
command MarkXToggleAutoForce let g:MarkxAutoLForce = (get(g:, 'MarkxAutoLForce', 0) ? 0 : 1) | echohl StatusMsg | echo "MarkX: Auto placement forced (recycle existing marks) ".((g:MarkxAutoLForce) ? 'on' : 'off')."" | echohl None

" Toggle the g:MarkxSteponAuto configuration setting
command MarkXToggleSteponAuto let g:MarkxSteponAuto = (get(g:, 'MarkxSteponAuto', 0) ? 0 : 1) | echohl StatusMsg | echo "MarkX: Step on auto sel. after manual placement ".((g:MarkxSteponAuto) ? 'on' : 'off')."" | echohl None

" Toggle the g:MarkxConfirmDelAll configuration setting
command MarkXToggleDelAllConfirm let g:MarkxConfirmDelAll = (get(g:, 'MarkxConfirmDelAll', 0) ? 0 : 1) | echohl StatusMsg | echo "MarkX: Confirm 'delete all' mappings ".((g:MarkxConfirmDelAll) ? 'on' : 'off')."" | echohl None

" Toggle the g:MarkxDelAllUGlobal configuration setting
command MarkXToggleDelUGlobal let g:MarkxDelAllUGlobal = (get(g:, 'MarkxDelAllUGlobal', 0) ? 0 : 1) | echohl StatusMsg | echo "MarkX: 'Delete all A-Z' mappings now operates ".((g:MarkxDelAllUGlobal) ? 'globally' : 'on local buffer only')."" | echohl None

" ------------------------------------------------------------------------------
" Default mappings (for details of global options used here, see README)

if get(g:, 'MarkxSetDefaultMaps', 1)
  nmap <silent> m <plug>(MarkXAdd)
  vmap <silent> m <plug>(MarkXAdd)

  nmap <silent> <leader>mm <plug>(MarkXAdda)
  vmap <silent> <leader>mm <plug>(MarkXAdda)
  nmap <silent> <leader>mM <plug>(MarkXAddA)
  vmap <silent> <leader>mM <plug>(MarkXAddA)

  nmap <silent> <leader>mn <plug>(MarkXAddaTest)
  nmap <silent> <leader>mN <plug>(MarkXAddATest)

  nmap <silent> <leader>md <plug>(MarkXDel)
  nmap <silent> <leader>ma <plug>(MarkXDelAllL)
  nmap <silent> <leader>mA <plug>(MarkXDelAllU)
  nmap <silent> <leader>mp <plug>(MarkXDelAllP)

  nmap <silent> <leader>mq <plug>(MarkXDelAllAutoL)
  nmap <silent> <leader>mQ <plug>(MarkXDelAllAutoU)

  nmap <silent> <leader>m+ <plug>(MarkXPrintMarksOnLine)
  nmap <silent> <leader>m= <plug>(MarkXPrintMarksInBuffer)

  nmap <silent> <leader>m~ <plug>(MarkXRefresh)
  nmap <silent> <leader>m# <plug>(MarkXRefreshAll)

  nmap <silent> <leader>m. <plug>(MarkXShowNone)
  nmap <silent> <leader>mo <plug>(MarkXShowStd)
  nmap <silent> <leader>mO <plug>(MarkXShowAll)
  nmap <silent> <leader>m@ <plug>(MarkXToggleShowAll)
endif

" Initialise.
" Note that this ought to be executed locally from ./autoload/markx.vim but it
" performs some error checking and the error messages are lost if run that way.
" Runing it from here on startup will preserve the error message output
call markx#Init()

" Events that trigger a refresh
augroup MarkX
autocmd!
augroup END

autocmd MarkX VimEnter,BufWinEnter,BufLeave,FileAppendPre,FileAppendPost,FileReadPost,FilterReadPost,ShellFilterPost * silent call markx#Refresh()
autocmd MarkX TabEnter,CursorHold * call markx#RefreshAll()

if get(g:, 'MarkxMoreEvents', 0) >= 1
  autocmd MarkX CursorHoldI,ModeChanged * call markx#Refresh()
endif

if get(g:, 'MarkxMoreEvents', 0) >= 2
  autocmd MarkX CursorMoved,CursorMovedI * call markx#Refresh()
endif

" CursorHoldI TabClosed TermEnter TermClose ????

if get(g:, 'MarkxMultiCfg', '+') !=# ''
  autocmd MarkX BufHidden,BufDelete * call markx#multimarks#Remove()
  autocmd MarkX TabLeave * call markx#multimarks#RemoveAll()
endif

" ------------------------------------------------------------------------------
" eof

