" --- Init:
if !exists('g:script_py_started')
    let g:script_py_started = 1

	let s:completion_channel = v:null

    let tags_file = '/home/anon/stow/vim/.vim/pack/hitags/start/hitags/cache/vim.tags'
    let log_file  = expand('<sfile>:p:h:h') . '/debug/server.log'
    let srv_exe   = expand('<sfile>:p:h:h') . '/bin/swp-completion-server.tcl'
    let cmd = [
        \ srv_exe,
        \ string(getpid()),
        \ tags_file
        \ ]

    call job_start(cmd, {
        \ 'out_io':  'file',
        \ 'out_name': log_file,
        \ 'err_io':  'file',
        \ 'err_name': log_file,
        \ })
endif

" --- Client protocol
function! s:open_channel()
	if type(s:completion_channel) != v:t_channel || ch_status(s:completion_channel) !=# 'open'
        let sockpath = 'unix:/tmp/completion-server-' . getpid() . '.sock'
        let s:completion_channel = ch_open(sockpath, {"mode": "nl"})
        if ch_status(s:completion_channel) !=# 'open'
            echoerr "Failed to open completion server socket."
			return 1
        endif
    endif
	return 0
endfunction

function! CompletionPush()
    if s:open_channel() | return | endif

    call ch_sendraw(s:completion_channel, "< \n")
endfunction

function! CompletionQuery(filter)
    if s:open_channel() | return | endif

    call ch_sendraw(s:completion_channel, '? ' . a:filter . "\n")
endfunction

function! CompletionPoll()
    if s:open_channel() | return | endif

	call ch_sendraw(s:completion_channel, "= \n")
	let response = ch_readraw(s:completion_channel)

	if response =~ '^> ' " Push
		let words = split(strpart(response, 2), ' ')
        return [0, words]
	elseif response =~ '^-' " Pass
        return [1, []]
	endif
endfunction


autocmd BufWritePost * call CompletionPush()
