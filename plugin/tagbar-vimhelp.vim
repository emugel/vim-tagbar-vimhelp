if exists("tagbar_helpindex_help2ctags_loaded")
    finish
else
    let tagbar_helpindex_help2ctags_loaded = 1
endif

if (!exists('g:tagbar_helpindex_help2ctags'))
    let s:path = fnamemodify(resolve(expand('<sfile>:p')), ':h')
    let g:tagbar_helpindex_help2ctags = s:path . '/../help2ctags.sh'
end

let s:tagbar_type_help = {
            \ 'ctagstype': 'help',
            \ 'ctagsbin' : g:tagbar_helpindex_help2ctags,
            \ 'ctagsargs' : '',
            \ 'kinds' : [
            \   's:Table of contents',
            \ ],
            \ 'sro' : '|',
            \ 'sort': 0,
            \ }

if (!exists('g:tagbar_type_help'))
    let g:tagbar_type_help = copy(s:tagbar_type_help)
endif
