" smartpunc - Smart input assistant for punctuations
" Version: 0.0.0
" Copyright (C) 2012 Kana Natsuno <http://whileimautomaton.net/>
" License: So-called MIT/X license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}

if exists('g:loaded_smartpunc')
  finish
endif




function! s:set_up_the_default_configuration()
  call smartpunc#define_default_rules()

  if !exists('g:smartpunc_no_default_key_mappings')
    let all_chars = map(copy(smartpunc#scope().available_nrules), 'v:val.char')
    let d = {}
    for char in all_chars
      let d[char] = char
    endfor
    let unique_chars = keys(d)

    let M = function('smartpunc#map_to_trigger')
    for char in unique_chars
      " Do not override existing key mappings.
      silent! call M('<unique> ' . char, char, char)
    endfor
    silent! call M('<unique> <C-h>', '<BS>', '<C-h>')
    silent! call M('<unique> <Return>', '<Enter>', '<Return>')
    silent! call M('<unique> <C-m>', '<Enter>', '<C-m>')
    silent! call M('<unique> <CR>', '<Enter>', '<CR>')
    silent! call M('<unique> <C-j>', '<Enter>', '<C-j>')
    silent! call M('<unique> <NL>', '<Enter>', '<NL>')
  endif
endfunction
call s:set_up_the_default_configuration()




let g:loaded_smartpunc = 1

" __END__
" vim: foldmethod=marker
