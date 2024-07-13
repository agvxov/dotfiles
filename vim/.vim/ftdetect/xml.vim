autocmd BufNewFile,BufRead *.xml,*.ui,*.axaml
	\ runtime! ftplugin/html.vim | 
	\ let g:xml_syntax_folding=1 |
	\ set foldmethod=syntax
