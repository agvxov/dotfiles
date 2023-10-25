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

" Compiler to use for preprocessing C/C++, so headers are respected
"  Either use "clang" or "gcc" or something compatible,
"  alternatively you will have to edit s:preprocessor
let s:preprocessor_executable = "clang"

" --- --------------------------- ---
" ---          Don't Touch        ---
" ---             Unless          ---
" --- You know What You Are Doing ---
" --- --------------------------- ---
let s:preprocessor       = s:preprocessor_executable . ' -fdirectives-only -E {input_} -o {output}'
let s:tags_filename      = 'tags'
let s:tags_file          = expand(s:polution_directory) . s:tags_filename
let s:tags_scriptname    = 'tags.vim'
let s:tags_script        = expand(s:polution_directory) . 'tags.vim'
"
let s:generator_script   = expand('~/.vim/plugin/HiTags/hitags.py')
let s:generation_command = 'python ' . s:generator_script .
                         \ ' -i ' . '"' . expand('%:p')        . '"' .
                         \ ' -p ' . '"' . s:preprocessor       . '"' .
                         \ ' -t ' . '"' . s:polution_directory . '"' .
                         \ '  > ' . '"' . s:tags_script        . '"'

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
