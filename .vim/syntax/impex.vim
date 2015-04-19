" Vim syntax file for hybris impex file
" Language: IMPEX
" Maintainer: Nevin Ng <nevin.ng@gmail.com>
" Filenames: *.impex
" Last Change: Feb 2014

if exists("b:current_syntax")
    finish
endif

syn case ignore

" Keywords
syn keyword impexHeaderMode INSERT UPDATE INSERT_UPDATE REMOVE nextgroup=impexTypeName skipwhite
syn keyword impexOperator default unique
syn keyword impexConstant true false

" Matches
syn match impexMarco /\$\w\+/
syn match impexComment /#.\+$/
syn match impexTypeName /\w\+;/ contained
syn match impexDelimiter "\v\;"

" Highlights
hi def link impexHeaderMode  Function
hi def link impexMarco       PreProc      
hi def link impexOperator    Statement      
hi def link impexComment     Comment
hi def link impexTypeName    Type 
hi def link impexDelimiter   Delimiter
hi def link impexConstant    Constant


let b:current_syntax = "impex"
