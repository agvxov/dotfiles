" popup_dictionary.vim - popup menu for inserting predefined values

if exists('g:loaded_popup_dictionary')
    finish
endif
let g:loaded_popup_dictionary = 1

" { name: { keys: [...], values: [...] } }
let s:dicts = {}

function! popup_dictionary#register(name, keys, values) abort
    if len(a:keys) != len(a:values)
        echoerr '[popup_dictionary] Key/value lists must be the same length (dict: ' . a:name . ')'
        return
    endif
    let s:dicts[a:name] = { 'keys': a:keys, 'values': a:values }
endfunction

function! s:OnSelect(name, id, result) abort
    if a:result <= 0
        return
    endif
    let val = s:dicts[a:name].values[a:result - 1]
    exec 'normal! i' . val
endfunction

function! popup_dictionary#show(name) abort
    if !has_key(s:dicts, a:name)
        echoerr '[popup_dictionary] Unknown dictionary: "' . a:name . '"'
        return
    endif
    let d = s:dicts[a:name]
    call popup_menu(d.keys, #{
        \ callback: {id, result -> s:OnSelect(a:name, id, result)},
        \ })
endfunction

command! -nargs=1 ShowDictionary call popup_dictionary#show(<q-args>)
