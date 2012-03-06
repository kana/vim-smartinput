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
" :: [NRule] -- it is ALWAYS sorted by priority in descending order.




"{{{2




" Interface  "{{{1
function! smartpunc#clear_rules()  "{{{2
  let s:available_nrules = []
endfunction




function! smartpunc#define_default_rules()  "{{{2
  " urules  "{{{
  let urules = {}
  let urules.names = []
  let urules.table = {}
  function! urules.add(name, urules)
    call add(self.names, a:name)
    let self.table[a:name] = a:urules
  endfunction
  call urules.add('()', [
  \   {'at': '\%#', 'char': '(', 'input': '()<Left>'},
  \   {'at': '(\%#)', 'char': ')', 'input': '<Right>'},
  \   {'at': '(\%#)', 'char': '<BS>', 'input': '<BS><Del>'},
  \   {'at': '\\\%#', 'char': '(', 'input': '('},
  \ ])
  call urules.add('[]', [
  \   {'at': '\%#', 'char': '[', 'input': '[]<Left>'},
  \   {'at': '\[\%#\]', 'char': ']', 'input': '<Right>'},
  \   {'at': '\[\%#\]', 'char': '<BS>', 'input': '<BS><Del>'},
  \   {'at': '\\\%#', 'char': '[', 'input': '['},
  \ ])
  call urules.add('{}', [
  \   {'at': '\%#', 'char': '{', 'input': '{}<Left>'},
  \   {'at': '{\%#}', 'char': '}', 'input': '<Right>'},
  \   {'at': '{\%#}', 'char': '<BS>', 'input': '<BS><Del>'},
  \   {'at': '\\\%#', 'char': '{', 'input': '{'},
  \ ])
  call urules.add('''''', [
  \   {'at': '\%#', 'char': '''', 'input': '''''<Left>'},
  \   {'at': '''\%#''', 'char': '''', 'input': '<Right>'},
  \   {'at': '''\%#''', 'char': '<BS>', 'input': '<BS><Del>'},
  \   {'at': '\\\%#', 'char': '''', 'input': ''''},
  \ ])
  call urules.add('""', [
  \   {'at': '\%#', 'char': '"', 'input': '""<Left>'},
  \   {'at': '"\%#"', 'char': '"', 'input': '<Right>'},
  \   {'at': '"\%#"', 'char': '<BS>', 'input': '<BS><Del>'},
  \   {'at': '\\\%#', 'char': '"', 'input': '"'},
  \ ])
  call urules.add('``', [
  \   {'at': '\%#', 'char': '`', 'input': '``<Left>'},
  \   {'at': '`\%#`', 'char': '`', 'input': '<Right>'},
  \   {'at': '`\%#`', 'char': '<BS>', 'input': '<BS><Del>'},
  \   {'at': '\\\%#', 'char': '`', 'input': '`'},
  \ ])
  call urules.add('English', [
  \   {'at': '\w\%#', 'char': '''', 'input': ''''},
  \ ])
  call urules.add('Lisp quote', [
  \   {'at': '\%#', 'char': '''', 'input': ''''},
  \   {'at': '\%#', 'char': '''', 'input': '''''<Left>',
  \    'syntax': ['Constant']},
  \ ])
  " FIXME: Add more rules like '(<Enter>)'
  call urules.add('(<Enter>)', [
  \   {'at': '(\%#)', 'char': '<Enter>', 'input': '<Enter>X<Enter>)<BS><Up><C-o>$<BS>'},
  \ ])
  "}}}

  " ft_urule_sets_table... "{{{
  let ft_urule_sets_table = {
  \   '*': [
  \     urules.table['()'],
  \     urules.table['[]'],
  \     urules.table['{}'],
  \     urules.table[''''''],
  \     urules.table['""'],
  \     urules.table['``'],
  \     urules.table['English'],
  \     urules.table['(<Enter>)'],
  \   ],
  \   'lisp': [
  \     urules.table['Lisp quote'],
  \   ],
  \   'scheme': [
  \     urules.table['Lisp quote'],
  \   ],
  \ }
  "}}}

  for urule_set in ft_urule_sets_table['*']
    for urule in urule_set
      call smartpunc#define_rule(urule)
    endfor
  endfor

  let overlaied_urules = {}
  let overlaied_urules.pairs = []  " [(URule, [FileType])]
  function! overlaied_urules.add(urule, ft)
    for [urule, fts] in self.pairs
      if urule is a:urule
        call add(fts, a:ft)
        return
      endif
    endfor
    call add(self.pairs, [a:urule, [a:ft]])
  endfunction
  for ft in filter(keys(ft_urule_sets_table), 'v:val != "*"')
    for urule_set in ft_urule_sets_table[ft]
      for urule in urule_set
        call overlaied_urules.add(urule, ft)
      endfor
    endfor
  endfor
  for [urule, fts] in overlaied_urules.pairs
    let completed_urule = copy(urule)
    let completed_urule.filetype = fts
    call smartpunc#define_rule(completed_urule)
  endfor

  " Add more useful rules?
endfunction

function! s:_operator_key_from(operator_name)
  let k = a:operator_name
  let k = substitute(k, '\V<', '<LT>', 'g')
  let k = substitute(k, '\V|', '<Bar>', 'g')
  return k
endfunction

function! s:_operator_pattern_from(operator_name)
  let k = a:operator_name
  return k
endfunction




function! smartpunc#define_rule(urule)  "{{{2
  let nrule = s:normalize_rule(a:urule)
  call s:insert_or_replace_a_rule(s:available_nrules, nrule)
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




function! smartpunc#map_trigger_keys(...)  "{{{2
  let overridep = 1 <= a:0 ? a:1 : 0

  let all_chars = map(copy(s:available_nrules), 'v:val.char')
  let d = {}
  for char in all_chars
    let d[char] = char
  endfor
  let unique_chars = keys(d)

  let M = function('smartpunc#map_to_trigger')
  let map_modifier = overridep ? '' : '<unique>'
  for char in unique_chars
    " Do not override existing key mappings.
    silent! call M(map_modifier . ' ' . char, char, char)
  endfor
  silent! call M(map_modifier . ' ' . '<C-h>', '<BS>', '<C-h>')
  silent! call M(map_modifier . ' ' . '<Return>', '<Enter>', '<Return>')
  silent! call M(map_modifier . ' ' . '<C-m>', '<Enter>', '<C-m>')
  silent! call M(map_modifier . ' ' . '<CR>', '<Enter>', '<CR>')
  silent! call M(map_modifier . ' ' . '<C-j>', '<Enter>', '<C-j>')
  silent! call M(map_modifier . ' ' . '<NL>', '<Enter>', '<NL>')
endfunction




"{{{2




" Misc.  "{{{1
function! smartpunc#invoke_the_initial_setup_if_necessary()  "{{{2
  " The initial setup is invoked implicitly by :source'ing the autoload file.
  " So that this function does nothing explicitly.
endfunction




function! smartpunc#scope()  "{{{2
  return s:
endfunction




function! smartpunc#sid()  "{{{2
  return maparg('<SID>', 'n')
endfunction
nnoremap <SID>  <SID>




function! s:calculate_rule_priority(snrule)  "{{{2
  return
  \ len(a:snrule.at)
  \ + (a:snrule.filetype is 0 ? 0 : 100 / len(a:snrule.filetype))
  \ + (a:snrule.syntax is 0 ? 0 : 100 / len(a:snrule.syntax))
  \ + 100 / len(a:snrule.mode)
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




function! s:insert_or_replace_a_rule(sorted_nrules, nrule)  "{{{2
  " a:sorted_nrules MUST be sorted by "hash" in descending order.
  " So that binary search can be applied
  "
  " * To replace an existing rule which is equivalent to a:nrule, and
  " * To insert a:nrule at the proper position to make the resulting
  "   a:sorted_nrules sorted.

  let i_min = 0
  let i_max = len(a:sorted_nrules) - 1
  let i_med = 0

  while i_min <= i_max
    let i_med = (i_min + i_max) / 2

    if a:nrule.hash ==# a:sorted_nrules[i_med].hash
      break
    elseif !(a:nrule.hash <# a:sorted_nrules[i_med].hash)
      let i_max = i_med - 1
    else
      let i_min = i_med + 1
    endif
  endwhile

  if i_min <= i_max
    " The same rule is found at i_med.
    let a:sorted_nrules[i_med] = a:nrule
  elseif i_max < i_med
    " The same rule is not found,
    " but it should be located between i_max and i_med.
    call insert(a:sorted_nrules, a:nrule, i_med + 0)
  else  " i_med < i_min
    " The same rule is not found,
    " but it should be located between i_med and i_min.
    call insert(a:sorted_nrules, a:nrule, i_med + 1)
  endif
endfunction




function! s:normalize_rule(urule)  "{{{2
  let nrule = deepcopy(a:urule)

  let nrule._char = s:decode_key_notation(nrule.char)

  let nrule._input = s:decode_key_notation(nrule.input)

  if !has_key(nrule, 'mode')
    let nrule.mode = 'i'
  endif

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

  let nrule.hash = string([
  \   printf('%06d', nrule.priority),
  \   nrule.at,
  \   nrule.char,
  \   nrule.filetype,
  \   nrule.syntax
  \ ])

  return nrule
endfunction




function! s:sid_value()  "{{{2
  return substitute(smartpunc#sid(), '<SNR>', "\<SNR>", 'g')
endfunction




"{{{2




" The initial setup  "{{{1
function! s:do_initial_setup()  "{{{2
  call smartpunc#define_default_rules()

  if !exists('g:smartpunc_no_default_key_mappings')
    call smartpunc#map_trigger_keys()
  endif
endfunction




" Invoke the initial setup.  "{{{2

if !exists('s:loaded_count')
  let s:loaded_count = 0
endif

let s:loaded_count += 1

if s:loaded_count == 1
  call s:do_initial_setup()
endif




"{{{2




" __END__  "{{{1
" vim: foldmethod=marker
