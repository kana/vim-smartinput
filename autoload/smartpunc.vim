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
let s:EXPIRED_NRULES = []  "{{{2
" :: [NRule]
"
" A special value for the deferred regularization.




let s:available_nrules = []  "{{{2
" :: [NRule] -- sorted by priority in descending order.
"
" * Only low-level utilities MAY use s:available_nrules directly.
" * Anything else MUST refer s:available_nrules via s:get_available_nrules().
"
" Because this variable should be "regularized" before actual use.
" But the regularization is somewhat expensive to run for each update.
" So that the regularization is deferred until this variable is really used.




let s:previously_available_nrules = s:EXPIRED_NRULES  "{{{2
" :: [NRule]
"
" A memo variable for the deferred regularization.




"{{{2




" Interface  "{{{1
function! smartpunc#clear_rules()  "{{{2
  let s:available_nrules = []
  let s:previously_available_nrules = s:EXPIRED_NRULES
endfunction




function! smartpunc#define_default_rules()  "{{{2
  let urules = {}
  let urules.names = []
  let urules.table = {}
  function! urules.add(name, urules)
    call add(self.names, a:name)
    let self.table[a:name] = a:urules
  endfunction
  " Other rules  "{{{
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
  call urules.add('<>', [
  \   {'at': '\%#', 'char': '<LT>', 'input': '<LT>><Left>'},
  \   {'at': '<\%#>', 'char': '>', 'input': '<Right>'},
  \   {'at': '<\%#>', 'char': '<BS>', 'input': '<BS><Del>'},
  \   {'at': '\\\%#', 'char': '<LT>', 'input': '<LT>'},
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
  call urules.add('case:', [
  \   {'at': '\C\<case\>.*\%#', 'char': ':', 'input': ':'},
  \ ])
  call urules.add('default:', [
  \   {'at': '\C\<default\>.*\%#', 'char': ':', 'input': ':'},
  \ ])
  call urules.add('x.y', [])
  call urules.add('f(x)', [])
  call urules.add('a[x]', [])
  call urules.add('new', [])
  call urules.add('typeof', [])
  call urules.add('checked', [])
  call urules.add('unchecked', [])
  call urules.add('default(T)', [])
  call urules.add('delegate', [])
  call urules.add('+ (unary)', [])
  call urules.add('- (unary)', [])
  call urules.add('!', [])
  call urules.add('~', [])
  call urules.add('(T)x', [])
  call urules.add('true', [])
  call urules.add('false', [])
  call urules.add('& (dereference)', [])
  call urules.add('sizeof', [])
  call urules.add('is', [])
  call urules.add('as', [])
  call urules.add('T<T>', [
  \   {'at': '\V\V < \%#', 'char': '>', 'input': '<BS><BS><BS><LT>><Left>'},
  \   {'at': '<\%#>', 'char': '<BS>', 'input': '<BS><Del>'},
  \ ])
  call urules.add('// comment', [
  \   {'at': '\V\V / \%#', 'char': '/', 'input': '<BS><BS><BS>// '},
  \   {'at': '// \%#', 'char': '<BS>', 'input': '<BS><BS><BS> / '},
  \ ])
  call urules.add('/// comment', [
  \   {'at': '\V\V// \%#', 'char': '/', 'input': '<BS><BS><BS>/// '},
  \   {'at': '/// \%#', 'char': '<BS>', 'input': '<BS><BS><BS><BS>// '},
  \ ])
  call urules.add('/* comment */', [
  \   {'at': '\V\V / \%#', 'char': '*', 'input': '<BS><BS><BS>/*  */<Left><Left><Left>'},
  \   {'at': '/\* \%# \*/', 'char': '<BS>', 'input': '<BS><BS><BS><Del><Del><Del> / '},
  \ ])
  "}}}
  " Single-character operator rules  "{{{
  for operator_name in [
  \   '=',
  \   '+',
  \   '-',
  \   '*',
  \   '/',
  \   '%',
  \   '<',
  \   '>',
  \   '|',
  \   '&',
  \   '^',
  \   '?',
  \   ':',
  \ ]
    let rule_set_name = operator_name
    let k = s:_operator_key_from(operator_name)
    let p = s:_operator_pattern_from(operator_name)
    let bs3 = repeat('<BS>', 3)
    call urules.add(rule_set_name, [
    \   {'at': '\%#', 'char': k, 'input': ' '.k.' '},
    \   {'at': '\V '.p.' \%#', 'char': '<BS>', 'input': bs3},
    \   {'at': '\S \%#', 'char': k, 'input': k.' '},
    \   {'at': '\V '.p.' \%#', 'char': '<Space>', 'input': ''},
    \ ])
  endfor
  "}}}
  " Double-character operator rules (normal)  "{{{
  for operator_name in [
  \   '==',
  \   '=>',
  \   '=~',
  \   '+=',
  \   '-=',
  \   '*=',
  \   '/=',
  \   '%=',
  \   '<=',
  \   '<<',
  \   '>=',
  \   '>>',
  \   '|=',
  \   '||',
  \   '&=',
  \   '&&',
  \   '^=',
  \   '??',
  \ ]
    let rule_set_name = operator_name
    let kt = s:_operator_key_from(operator_name[1])
    let k1 = s:_operator_key_from(operator_name[0])
    let k2 = s:_operator_key_from(operator_name)
    let p1 = s:_operator_pattern_from(operator_name[0])
    let p2 = s:_operator_pattern_from(operator_name)
    let bs3 = repeat('<BS>', 3)
    let bs4 = repeat('<BS>', 4)
    call urules.add(rule_set_name, [
    \   {'at': '\V '.p1.' \%#', 'char': kt, 'input': bs3.' '.k2.' '},
    \   {'at': '\V '.p2.' \%#', 'char': '<BS>', 'input': bs4.' '.k1.' '},
    \   {'at': '\V '.p2.' \%#', 'char': '<Space>', 'input': ''},
    \ ])
  endfor
  "}}}
  " Double-character operator rules (!=, etc)  "{{{
  for operator_name in [
  \   '!=',
  \   '!~',
  \ ]
    let rule_set_name = operator_name
    let kt = s:_operator_key_from(operator_name[1])
    let k1 = s:_operator_key_from(operator_name[0])
    let k2 = s:_operator_key_from(operator_name)
    let p1 = s:_operator_pattern_from(operator_name[0])
    let p2 = s:_operator_pattern_from(operator_name)
    let bs1 = repeat('<BS>', 1)
    let bs4 = repeat('<BS>', 4)
    call urules.add(rule_set_name, [
    \   {'at': '\V'.p1.'\%#', 'char': kt, 'input': bs1.' '.k2.' '},
    \   {'at': '\V '.p2.' \%#', 'char': '<BS>', 'input': bs4.k1},
    \   {'at': '\V '.p2.' \%#', 'char': '<Space>', 'input': ''},
    \ ])
  endfor
  "}}}
  " Double-character operator rules (++, etc)  "{{{
  for operator_name in [
  \   '++',
  \   '--',
  \   '->',
  \ ]
    let rule_set_name = operator_name
    let kt = s:_operator_key_from(operator_name[1])
    let k1 = s:_operator_key_from(operator_name[0])
    let k2 = s:_operator_key_from(operator_name)
    let p1 = s:_operator_pattern_from(operator_name[0])
    let p2 = s:_operator_pattern_from(operator_name)
    let bs2 = repeat('<BS>', 2)
    let bs3 = repeat('<BS>', 3)
    call urules.add(rule_set_name, [
    \   {'at': '\V '.p1.' \%#', 'char': kt, 'input': bs3.k2},
    \   {'at': '\V'.p2.'\%#', 'char': '<BS>', 'input': bs2.' '.k1.' '},
    \ ])
  endfor
  "}}}
  " Triple-character operator rules  "{{{
  for operator_name in [
  \   '===',
  \   '!==',
  \   '<=>',
  \   '<<=',
  \   '>>=',
  \ ]
    let rule_set_name = operator_name
    let kt = s:_operator_key_from(operator_name[2])
    let k2 = s:_operator_key_from(operator_name[:1])
    let k3 = s:_operator_key_from(operator_name)
    let p2 = s:_operator_pattern_from(operator_name[:1])
    let p3 = s:_operator_pattern_from(operator_name)
    let bs4 = repeat('<BS>', 4)
    let bs5 = repeat('<BS>', 5)
    call urules.add(rule_set_name, [
    \   {'at': '\V '.p2.' \%#', 'char': kt, 'input': bs4.' '.k3.' '},
    \   {'at': '\V '.p3.' \%#', 'char': '<BS>', 'input': bs5.' '.k2.' '},
    \   {'at': '\V '.p3.' \%#', 'char': '<Space>', 'input': ''},
    \ ])
  endfor
  "}}}

  " ft_urule_sets_table... "{{{
  let ft_urule_sets_table = {
  \   '*': [
  \     urules.table['()'],
  \     urules.table['[]'],
  \     urules.table['{}'],
  \     urules.table['<>'],
  \     urules.table[''''''],
  \     urules.table['""'],
  \     urules.table['``'],
  \     urules.table['English'],
  \     urules.table['(<Enter>)'],
  \   ],
  \   'cs': [
  \     urules.table['x.y'],
  \     urules.table['f(x)'],
  \     urules.table['a[x]'],
  \     urules.table['++'],
  \     urules.table['--'],
  \     urules.table['new'],
  \     urules.table['typeof'],
  \     urules.table['checked'],
  \     urules.table['unchecked'],
  \     urules.table['default(T)'],
  \     urules.table['delegate'],
  \     urules.table['->'],
  \
  \     urules.table['+ (unary)'],
  \     urules.table['- (unary)'],
  \     urules.table['!'],
  \     urules.table['~'],
  \     urules.table['(T)x'],
  \     urules.table['true'],
  \     urules.table['false'],
  \     urules.table['& (dereference)'],
  \     urules.table['sizeof'],
  \
  \     urules.table['*'],
  \     urules.table['/'],
  \     urules.table['%'],
  \
  \     urules.table['+'],
  \     urules.table['-'],
  \
  \     urules.table['<<'],
  \     urules.table['>>'],
  \
  \     urules.table['<'],
  \     urules.table['>'],
  \     urules.table['<='],
  \     urules.table['>='],
  \     urules.table['is'],
  \     urules.table['as'],
  \     urules.table['=='],
  \     urules.table['!='],
  \
  \     urules.table['&'],
  \     urules.table['^'],
  \     urules.table['|'],
  \
  \     urules.table['&&'],
  \     urules.table['||'],
  \
  \     urules.table['??'],
  \     urules.table['?'],
  \     urules.table[':'],
  \     urules.table['case:'],
  \     urules.table['default:'],
  \
  \     urules.table['='],
  \     urules.table['+='],
  \     urules.table['-='],
  \     urules.table['*='],
  \     urules.table['/='],
  \     urules.table['%='],
  \     urules.table['&='],
  \     urules.table['|='],
  \     urules.table['^='],
  \     urules.table['<<='],
  \     urules.table['>>='],
  \
  \     urules.table['=>'],
  \
  \     urules.table['T<T>'],
  \     urules.table['// comment'],
  \     urules.table['/// comment'],
  \     urules.table['/* comment */'],
  \   ],
  \   'javascript': [
  \     urules.table['='],
  \     urules.table['=='],
  \     urules.table['==='],
  \     urules.table['!='],
  \     urules.table['!=='],
  \   ],
  \   'lisp': [
  \     urules.table['Lisp quote'],
  \   ],
  \   'ruby': [
  \     urules.table['<'],
  \     urules.table['<='],
  \     urules.table['<=>'],
  \   ],
  \   'scheme': [
  \     urules.table['Lisp quote'],
  \   ],
  \   'vim': [
  \     urules.table['='],
  \     urules.table['=~'],
  \     urules.table['!~'],
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
  call s:remove_a_same_rule(s:available_nrules, nrule)
  call add(s:available_nrules, nrule)
  let s:previously_available_nrules = s:EXPIRED_NRULES
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
  let nrule = s:find_the_most_proper_rule(s:get_available_nrules(), a:char)
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
  return
  \ a:nrule1.at ==# a:nrule2.at
  \ && a:nrule1.char ==# a:nrule2.char
  \ && type(a:nrule1.filetype) ==# type(a:nrule2.filetype)
  \ && a:nrule1.filetype ==# a:nrule2.filetype
  \ && type(a:nrule1.syntax) ==# type(a:nrule2.syntax)
  \ && a:nrule1.syntax ==# a:nrule2.syntax
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




function! s:get_available_nrules()  "{{{2
  if s:previously_available_nrules is s:EXPIRED_NRULES
    call
    \ map(
    \   reverse(
    \     sort(
    \       map(
    \         s:available_nrules,
    \         '[printf("%06d:%s", v:val.priority, v:val.at), v:val]'
    \       )
    \     )
    \   ),
    \   'v:val[1]'
    \ )

    let s:previously_available_nrules = s:available_nrules
  endif

  return s:available_nrules
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




"{{{2




" __END__  "{{{1
" vim: foldmethod=marker
