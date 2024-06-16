" Vim syntax file
" Language: Imageboard

let b:current_syntax = "ib"


" Matching:
syn match Dice			"dice+\d\d*d\d\d*"
syn match Dice			"\d\d*d\d\d*"

syn region Bold			start="\[b\]" 			end="\[/b\]"
syn region Italic		start="\[i\]" 			end="\[/i\]"
syn region Spoiler		start="\[spoiler\]" 	end="\[/spoiler\]"
syn region Code			start="\[code\]" 		end="\[/code\]"

syn region Blue			start="\[blue\]"		end="\[/blue\]"
syn region Red			start="\[red\]"			end="\[/red\]"
syn region Green		start="\[green\]"		end="\[/green\]"

syn match GreenText		"^\s*>.*$"
syn match RedText		"==.*=="
syn match PurpleText	"--.*--"
syn match PinkText		"^\s*<.*$"

syn keyword ib_keyword		OP You SAGE sage desu


" Highlighting:
hi link Dice				SpecialKey
hi def Italic				term=italic		cterm=italic	gui=italic
hi def Bold					term=bold		cterm=bold		gui=bold
hi def Spoiler				term=reverse	cterm=reverse	gui=reverse
hi link Code				Statement
hi def Blue					ctermfg=4		guifg=Blue
hi def Red					ctermfg=9		guifg=Red
hi def Green				ctermfg=40		guifg=Green
hi def GreenText			term=underline	ctermfg=82 		guifg=#98af68
hi def RedText				term=underline	ctermfg=1 		guifg=#b1171d
hi def PurpleText			term=underline	ctermfg=13 		guifg=#7129e2
hi def PinkText				term=underline	ctermfg=212 	guifg=#de8492
hi link ib_keyword			Identifier
