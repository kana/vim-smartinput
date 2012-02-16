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




function! smartpunc#define_default_rules()  "{{{2
  let D = function('smartpunc#define_rule')

  " Complete the corresponding character automatically:
  call D({'at': '\%#', 'char': '(', 'input': '()<Left>'})
  call D({'at': '\%#', 'char': '[', 'input': '[]<Left>'})
  call D({'at': '\%#', 'char': '{', 'input': '{}<Left>'})
  call D({'at': '\%#', 'char': '<LT>', 'input': '<LT>><Left>'})
  call D({'at': '\%#', 'char': '''', 'input': '''''<Left>'})
  call D({'at': '\%#', 'char': '"', 'input': '""<Left>'})
  call D({'at': '\%#', 'char': '`', 'input': '``<Left>'})

  " Leave from the current block easily:
  call D({'at': '(\%#)', 'char': ')', 'input': '<Right>'})
  call D({'at': '\[\%#\]', 'char': ']', 'input': '<Right>'})
  call D({'at': '{\%#}', 'char': '}', 'input': '<Right>'})
  call D({'at': '<\%#>', 'char': '>', 'input': '<Right>'})
  call D({'at': '''\%#''', 'char': '''', 'input': '<Right>'})
  call D({'at': '"\%#"', 'char': '"', 'input': '<Right>'})
  call D({'at': '`\%#`', 'char': '`', 'input': '<Right>'})

  " Undo the completion easily:
  " FIXME: <BS> vs <C-h>
  call D({'at': '(\%#)', 'char': '<BS>', 'input': '<BS><Del>'})
  call D({'at': '\[\%#\]', 'char': '<BS>', 'input': '<BS><Del>'})
  call D({'at': '{\%#}', 'char': '<BS>', 'input': '<BS><Del>'})
  call D({'at': '<\%#>', 'char': '<BS>', 'input': '<BS><Del>'})
  call D({'at': '''\%#''', 'char': '<BS>', 'input': '<BS><Del>'})
  call D({'at': '"\%#"', 'char': '<BS>', 'input': '<BS><Del>'})
  call D({'at': '`\%#`', 'char': '<BS>', 'input': '<BS><Del>'})

  " Care to input strings and regular expressions:
  call D({'at': '\\\%#', 'char': '(', 'input': '('})
  call D({'at': '\\\%#', 'char': '[', 'input': '['})
  call D({'at': '\\\%#', 'char': '{', 'input': '{'})
  call D({'at': '\\\%#', 'char': '<LT>', 'input': '<LT>'})
  call D({'at': '\\\%#', 'char': '''', 'input': ''''})
  call D({'at': '\\\%#', 'char': '"', 'input': '"'})
  call D({'at': '\\\%#', 'char': '`', 'input': '`'})

  " Care to input English words:
  call D({'at': '\w\%#', 'char': '''', 'input': ''''})

  " Care to write Lisp/Scheme source code:
  call D({'at': '\%#', 'char': '''', 'input': '''',
  \       'filetype': ['lisp', 'scheme']})
  call D({'at': '\%#', 'char': '''', 'input': '''''<Left>',
  \       'filetype': ['lisp', 'scheme'],
  \       'syntax': ['String']})

  " Care to write C-like syntax source code:
  " FIXME: <Return> vs <Enter> vs <CR> vs <C-m> vs <C-j>
  call D({'at': '(\%#)', 'char': '<Return>',
  \      'input': '<Return>X<Return>)<BS><Up><C-o>$<BS>'})
  " FIXME: Add more rules.

  " Add more useful rules?
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




function! smartpunc#map_to_trigger(lhs, rhs_char, rhs_fallback)  "{{{2
  " FIXME: Keep automatic indentation for fallback <Return>.
  let char_expr = s:_encode_for_map_char_expr(a:rhs_char)
  let fallback_expr = s:_encode_for_map_char_expr(a:rhs_fallback)
  let rule_expr = printf('<SID>_find_the_most_proper_rule(%s)', char_expr)
  let script = printf('call <SID>do_smart_input_assistant(%s, %s)',
  \                   rule_expr,
  \                   fallback_expr)
  execute printf('inoremap %s %s  <C-\><C-o>:%s<Return>%s',
  \              '<script> <silent>',
  \              a:lhs,
  \              script,
  \              '<SID>(adjust-the-cursor)')
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

inoremap <expr> <SID>(adjust-the-cursor)  <SID>_adjust_the_cursor()

function! s:_adjust_the_cursor()
  " See also s:do_smart_input_assistant.  <Right> is usually enough to adjust
  " the cursor.  But the cursor may be moved to an empty line.  It often
  " happens for rules triggered by <Return>.  In this case, there is no room
  " to <Right>, so that the cursor should not be adjusted to avoid beep.
  return col('.') == col('$') ? '' : "\<Right>"
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
  " 1. <C-\><C-o>
  " 2. :call s:do_smart_input_assistant(...)<Return>
  " 3. <SID>(adjust-the-cursor)
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
  "   possible in this function.  If the cursor is at the last character of
  "   the line, it is not possible to adjust its position to the end of the
  "   line unless 'virtualedit' is configured.  That's why
  "   <SID>(adjust-the-cursor) is done after after the alternate "input".

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




" Start-up  "{{{2

function! smartpunc#require()
  " To :source this file from plugin/smartpunc.vim.
endfunction

function! s:set_up_the_default_configuration()
  if !exists('s:is_already_configured')
    call smartpunc#define_default_rules()

    if !exists('g:smartpunc_no_default_key_mappings')
      let all_chars = map(copy(s:available_nrules), 'v:val.char')
      let d = {}
      for char in all_chars
        let d[char] = char
      endfor
      let unique_chars = keys(d)

      for char in unique_chars
        " Do not override existing key mappings.
        silent! call smartpunc#map_to_trigger('<unique> ' . char, char, char)
      endfor
    endif

    let s:is_already_configured = !0
  endif
endfunction

call s:set_up_the_default_configuration()




"{{{2




" __END__  "{{{1
" vim: foldmethod=marker
