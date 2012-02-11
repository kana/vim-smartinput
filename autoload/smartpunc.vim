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




function! smartpunc#map_to_trigger(lhs, rhs_char)  "{{{2
  " FIXME: Avoid beeping on fallback <Return>.
  "        It seems to be caused by the last cursor adjustment (<Right>)
  "        if the new line does not contain any character.
  " FIXME: Keep automatic indentation for fallback <Return>.
  let char_expr = s:_encode_for_map_char_expr(a:rhs_char)
  let rule_expr = printf('<SID>_find_the_most_proper_rule(%s)', char_expr)
  let script = printf('call <SID>do_smart_input_assistant(%s, %s)',
  \                   rule_expr,
  \                   char_expr)
  execute printf('inoremap <silent> %s  <C-\><C-o>:%s<Return><Right>',
  \              a:lhs,
  \              script)
endfunction

function! s:_encode_for_map_char_expr(rhs_char)
  let s = a:rhs_char
  let s = substitute(s, '<', '<Bslash><LT>', 'g')
  let s = escape(s, '"')
  let s = '"' . s . '"'
  return s
endfunction

function! s:_find_the_most_proper_rule(char)
  return s:find_the_most_proper_rule(s:available_nrules, a:char)
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




function! s:do_smart_input_assistant(nrule, fallback_char)  "{{{2
  " This function MUST be called in Insert mode with the following step:
  " <C-\><C-o>:call s:do_smart_input_assistant(...)<Return><Right>
  "
  " Because the treatment of the cursor position to do smart input assistant
  " is very complex:
  "
  " - <C-\><C-o> temporarily escapes from Insert mode while keeping the cursor
  "   position even if the cursor is at the end of the line.  It is useful to
  "   detect the correct cursor position for the later process.
  " - The alternate "input" in a:nrule is fed by ":normal! a" or ":normal! i".
  "   Though <C-\><C-o> keeps the cursor position at the end of the line,
  "   ":normal! a" and ":normal! i" work as if <C-o> is used to escape.
  "   So that ":normal! a" must be used if the cursor at the end of the line,
  "   otherwise ":normal! i" must be used.
  " - <Esc> from Insert mode has a side effect; the cursor is moved to left by
  "   1 character.  Though this side effect must be countered, it is not
  "   possible in this function.  Because the counter must be done after the
  "   alternate "input".  If the cursor is at the last character of the line,
  "   it is not possible to adjust its position to the end of the line unless
  "   'virtualedit' is configured.

  execute 'normal!'
  \       (col('.') == col('$') ? 'a' : 'i')
  \       . (a:nrule is 0 ? a:fallback_char : a:nrule._input)
endfunction




function! s:find_the_most_proper_rule(nrules, char)  "{{{2
  " FIXME: Optimize for speed if necessary.
  let syntax_names = map(synstack(line('.'), col('.')),
  \                      'synIDattr(synIDtrans(v:val), "name")')

  for nrule in a:nrules
    if !(a:char ==# nrule._char)
      continue
    endif

    if !(search(nrule.at, 'bcnW'))
      continue
    endif

    if !(nrule.filetype is 0
    \    ? !0
    \    : 0 <= index(nrule.filetype,  &l:filetype))
      continue
    endif

    if !(nrule.syntax is 0
    \    ? !0
    \    : 0 <= max(map(copy(nrule.syntax), 'index(syntax_names, v:val)')))
      continue
    endif

    return nrule
  endfor

  return 0
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
