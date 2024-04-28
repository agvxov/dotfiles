" --- ------ ----
" --- Config ----
" --- ------ ----

" Folder to store all dynamically generated files in
"   + tags files
"   + highlighting scripts
"  I do not recommend using '.' especially if you don't auto cd with vim
"  ~/.vim/plugin/HiTags/ is guaranteed to exist after installation,
"  thats why it's the default
"  otherwise you are responsible for creating your own
let s:polution_directory = expand('~/.vim/plugin/HiTags/')

" Compiler_Collection_based_Preprocessing:
if 0
	"  Compiler to use for preprocessing C/C++, so headers are respected
	"   Either use "clang" or "gcc" or something compatible,
	"   alternatively you will have to edit s:preprocessor
	let s:preprocessor_executable = "clang"
	"let s:preprocessor_executable = "gcc"
	let s:preprocessor            = s:preprocessor_executable . ' -fdirectives-only -E {input_} -o {output}'
endif

" Stand_alone_preprocessor:
"  The only implementation i know is fcpp (https://github.com/bagder/fcpp.git)
"  However, it has the major advantage that it will only warn on missing
"  headers and not error. Meaning a tool chain using '-I' doesn't break
"  everything.
let s:preprocessor = "fcpp -LL {input_} {output}"

" --- --------------------------- ---
" ---          Don't Touch        ---
" ---             Unless          ---
" --- You know What You Are Doing ---
" --- --------------------------- ---
let s:tags_filename      = 'tags'
let s:tags_file          = expand(s:polution_directory) . s:tags_filename
let s:tags_scriptname    = 'tags.vim'
let s:tags_script        = expand(s:polution_directory) . 'tags.vim'
let s:sigs_script        = expand(s:polution_directory) . 'sigs.vim'
"
let s:generator_script   = expand('~/.vim/plugin/HiTags/hitags.py')
let s:generation_command =
                         \ 'python ' . s:generator_script .
                         \ ' -i ' . '"' . expand('%:p')        . '"' .
                         \ ' -p ' . '"' . s:preprocessor       . '"' .
                         \ ' -t ' . '"' . s:polution_directory . '"' .
                         \ ' hi ' .
                         \ '  > ' . '"' . s:tags_script        . '"' .
						 \ ';' .
                         \ 'python ' . s:generator_script .
                         \ ' -i ' . '"' . expand('%:p')        . '"' .
                         \ ' -p ' . '"' . s:preprocessor       . '"' .
                         \ ' -t ' . '"' . s:polution_directory . '"' .
                         \ ' sig ' .
                         \ '  > ' . '"' . s:sigs_script        . '"'

" --- Signature stuff ---
function! SigDebug()
	echo s:generation_command
endfunction


function! SigInit()
	let g:signatures = {}

	autocmd TextChangedI * call SigPopup()
endfunction

call SigInit()

function! SigPopup()
	let key = matchstr(getline('.')[:col('.')-2], '\k\+$')
	if has_key(g:signatures, key)
		call popup_atcursor(g:signatures[key], #{} )
	endif
endfunction

function! Sig()
	execute 'source ' . s:sigs_script
endfunction

if exists('g:sigs_events')
	for e in g:sigs_events
		execute "autocmd " . e . " * Sig"
	endfor
endif

command! Sig    :call Sig()
" --- --- ---

function! HiTagsUpdate()
	let pid = system(s:generation_command)

	if v:shell_error != 0
		echohl ErrorMsg
		echomsg "error: " . s:generator_script . " failed."
		echohl NONE
		return 1
	endif
endfunction

function! HiTagsClean()
	syn clear HiTagSpecial
	syn clear HiTagFunction
	syn clear HiTagType
	syn clear HiTagConstant
	syn clear HiTagIdentifier
endfunction

function! HiTagsHighlight()
	execute 'source ' . s:tags_script
endfunction

function! HiTagsDo()
	call HiTagsUpdate()
	call HiTagsClean()
	call HiTagsHighlight()
endfunction

" --- Hook up everything ---
if exists('g:hitags_events')
	for e in g:hitags_events
		execute "autocmd " . e . " * HiTagsDo"
	endfor
endif

hi link HiTagSpecial    Special
hi link HiTagFunction   Function
hi link HiTagType       Type
hi link HiTagConstant   Constant
hi link HiTagIdentifier Identifier

command! HiTagsUpdate    :call HiTagsUpdate()
command! HiTagsClean     :call HiTagsClean()
command! HiTagsHighlight :call HiTagsHighlight()
command! HiTagsDo        :call HiTagsDo()
