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
" Naming guidelines  "{{{1
" Rules  "{{{2
"
" "urule" stands for "Unnormalized RULE".
" urules are rules written by users.
" Optional items may be omitted from urules.
"
" "nrule" stands for "Normalized RULE".
" nrules are rules completed with all optional items and internal items.
"
" "snrule" stands for "SemiNormalized RULE".
" snrules are mostly same as nrules, the only one difference is that
" "priority" items may be omitted from snrules.








" Variables  "{{{1
let s:available_nrules = []  "{{{2
" :: [NRule] -- sorted by priority in descending order.




"{{{2




" Interface  "{{{1
function! smartpunc#clear_rules()  "{{{2
  let s:available_nrules = []
endfunction




function! smartpunc#define_rule(urule)  "{{{2
  let nrule = s:normalize_rule(a:urule)
  call s:remove_a_same_rule(s:available_nrules, nrule)
  call add(s:available_nrules, nrule)
  call sort(s:available_nrules, 's:nrule_comparer_desc')
endfunction

function! s:nrule_comparer_desc(nrule1, nrule2)
  return a:nrule2.priority - a:nrule1.priority
endfunction




"{{{2




" Misc.  "{{{1
function! smartpunc#scope()  "{{{2
  return s:
endfunction




function! smartpunc#sid()  "{{{2
  return maparg('<SID>', 'n')
endfunction
nnoremap <SID>  <SID>




function! s:are_same_rules(nrule1, nrule2)  "{{{2
  for key in filter(keys(a:nrule1), 'v:val !=# "input" && v:val !=# "_input"')
    if type(a:nrule1[key]) !=# type(a:nrule2[key])
    \  || a:nrule1[key] !=# a:nrule2[key]
      return !!0
    endif
  endfor
  return !0
endfunction




function! s:calculate_rule_priority(snrule)  "{{{2
  return
  \ len(a:snrule.at)
  \ + (a:snrule.filetype is 0 ? 0 : 100 / len(a:snrule.filetype))
  \ + (a:snrule.syntax is 0 ? 0 : 100 / len(a:snrule.syntax))
endfunction




function! s:decode_key_notation(s)  "{{{2
  return eval('"' . escape(a:s, '<"\') . '"')
endfunction




function! s:normalize_rule(urule)  "{{{2
  let nrule = deepcopy(a:urule)

  let nrule._char = s:decode_key_notation(nrule.char)

  let nrule._input = s:decode_key_notation(nrule.input)

  if has_key(nrule, 'filetype')
    call sort(nrule.filetype)
  else
    let nrule.filetype = 0
  endif

  if has_key(nrule, 'syntax')
    call sort(nrule.syntax)
  else
    let nrule.syntax = 0
  endif

  let nrule.priority =  s:calculate_rule_priority(nrule)

  return nrule
endfunction




function! s:remove_a_same_rule(nrules, nrule)  "{{{2
  for i in range(len(a:nrules))
    if s:are_same_rules(a:nrule, a:nrules[i])
      call remove(a:nrules, i)
      return
    endif
  endfor
endfunction




"{{{2




" __END__  "{{{1
" vim: foldmethod=marker
