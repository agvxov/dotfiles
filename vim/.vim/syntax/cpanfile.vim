" Vim syntax file for cpanfile.
if exists("b:current_syntax")
  finish
endif

syn keyword cpanfileRequirement requires recommends suggests conflicts
syn keyword cpanfileRequirement configure_requires build_requires test_requires author_requires
syn keyword cpanfilePhase       on
syn keyword cpanfileFeature     feature

" ---
hi def link cpanfileRequirement Operator
hi def link cpanfilePhase       Conditional
hi def link cpanfileFeature     Type
hi def link cpanfileTypo        Error

runtime! syntax/perl.vim

" Error: common typo (singular 'require' is usually a mistake in cpanfile)
syn match   cpanfileTypo /\<require\>/

let b:current_syntax = "cpanfile"
