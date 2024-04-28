autocmd BufNewFile,BufRead *.xml,*ui
	\ runtime! ftplugin/html.vim | 
	\ let g:xml_syntax_folding=1 |
	\ set foldmethod=syntax
