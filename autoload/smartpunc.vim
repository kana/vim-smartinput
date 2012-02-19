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
  " This completion is not defined by default,
  " because it is depended on the current context.
  " call D({'at': '\%#', 'char': '<LT>', 'input': '<LT>><Left>'})
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
  \       'syntax': ['Constant']})

  " Care to write C-like syntax source code:
  call D({'at': '(\%#)', 'char': '<Enter>',
  \      'input': '<Enter>X<Enter>)<BS><Up><C-o>$<BS>'})
  " FIXME: Add more rules.

  " Surround operators with spaces:
  call D({'at': '\%#', 'char': '=', 'input': ' = '})
  call D({'at': ' = \%#', 'char': '<BS>', 'input': '<BS><BS><BS>'})
  call D({'at': ' = \%#', 'char': '=', 'input': '<BS><BS><BS> == '})
  call D({'at': ' == \%#', 'char': '<BS>', 'input': '<BS><BS><BS><BS> = '})
  call D({'at': '!\%#', 'char': '=', 'input': '<BS> != '})
  call D({'at': ' != \%#', 'char': '<BS>', 'input': '<BS><BS><BS><BS>!'})
  call D({'at': '\%#', 'char': '+', 'input': ' + '})
  call D({'at': ' + \%#', 'char': '<BS>', 'input': '<BS><BS><BS>'})
  call D({'at': ' + \%#', 'char': '=', 'input': '<BS><BS><BS> += '})
  call D({'at': ' += \%#', 'char': '<BS>', 'input': '<BS><BS><BS><BS> + '})
  call D({'at': '\%#', 'char': '-', 'input': ' - '})
  call D({'at': ' - \%#', 'char': '<BS>', 'input': '<BS><BS><BS>'})
  call D({'at': ' - \%#', 'char': '=', 'input': '<BS><BS><BS> -= '})
  call D({'at': ' -= \%#', 'char': '<BS>', 'input': '<BS><BS><BS><BS> - '})
  call D({'at': '\%#', 'char': '*', 'input': ' * '})
  call D({'at': ' \* \%#', 'char': '<BS>', 'input': '<BS><BS><BS>'})
  call D({'at': ' \* \%#', 'char': '=', 'input': '<BS><BS><BS> *= '})
  call D({'at': ' \*= \%#', 'char': '<BS>', 'input': '<BS><BS><BS><BS> * '})
  call D({'at': '\%#', 'char': '/', 'input': ' / '})
  call D({'at': ' / \%#', 'char': '<BS>', 'input': '<BS><BS><BS>'})
  call D({'at': ' / \%#', 'char': '=', 'input': '<BS><BS><BS> /= '})
  call D({'at': ' /= \%#', 'char': '<BS>', 'input': '<BS><BS><BS><BS> / '})
  call D({'at': '\%#', 'char': '%', 'input': ' % '})
  call D({'at': ' % \%#', 'char': '<BS>', 'input': '<BS><BS><BS>'})
  call D({'at': ' % \%#', 'char': '=', 'input': '<BS><BS><BS> %= '})
  call D({'at': ' %= \%#', 'char': '<BS>', 'input': '<BS><BS><BS><BS> % '})
  call D({'at': '\%#', 'char': '<LT>', 'input': ' <LT> '})
  call D({'at': ' < \%#', 'char': '<BS>', 'input': '<BS><BS><BS>'})
  call D({'at': ' < \%#', 'char': '=', 'input': '<BS><BS><BS> <LT>= '})
  call D({'at': ' <= \%#', 'char': '<BS>', 'input': '<BS><BS><BS><BS> <LT> '})
  call D({'at': '\%#', 'char': '>', 'input': ' > '})
  call D({'at': ' > \%#', 'char': '<BS>', 'input': '<BS><BS><BS>'})
  call D({'at': ' > \%#', 'char': '=', 'input': '<BS><BS><BS> >= '})
  call D({'at': ' >= \%#', 'char': '<BS>', 'input': '<BS><BS><BS><BS> > '})

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
  " According to :help 'autoindent' --
  "
  " > Copy indent from current line when starting a new line
  " > (typing <CR> in Insert mode or when using the "o" or "O" command).
  " > If you do not type anything on the new line except <BS> or CTRL-D
  " > and then type <Esc>, CTRL-O or <CR>, the indent is deleted again.
  "
  " So that a:rhs_fallback MUST be mapped from a:lhs without leaving from
  " Insert mode to keep the behavior on automatic indentation when
  " a:rhs_fallback == '<Enter>',
  let char_expr = s:_encode_for_map_char_expr(a:rhs_char)
  let fallback_expr = s:_encode_for_map_char_expr(a:rhs_fallback)
  execute printf('inoremap %s %s  <SID>_trigger_or_fallback(%s, %s)',
  \              '<script> <expr> <silent>',
  \              a:lhs,
  \              char_expr,
  \              fallback_expr)
endfunction

function! s:_encode_for_map_char_expr(rhs_char)
  let s = a:rhs_char
  let s = substitute(s, '<', '<Bslash><LT>', 'g')
  let s = escape(s, '"')
  let s = '"' . s . '"'
  return s
endfunction

function! s:_trigger_or_fallback(char, fallback)
  let nrule = s:find_the_most_proper_rule(s:available_nrules, a:char)
  if nrule is 0
    return a:fallback
  else
    return nrule._input
  endif
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




function! s:sid_value()  "{{{2
  return substitute(smartpunc#sid(), '<SNR>', "\<SNR>", 'g')
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

    let s:is_already_configured = !0
  endif
endfunction

call s:set_up_the_default_configuration()




"{{{2




" __END__  "{{{1
" vim: foldmethod=marker
