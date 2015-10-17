" panacea - Provide smart input assistant
" Version: 0.0.5
" Copyright (C) 2015 Alexander Tsepkov <atsepkov@gmail.com>
" Originally by: (C) 2012 Kana Natsuno <http://whileimautomaton.net/>
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
function! panacea#clear_rules()  "{{{2
  let s:available_nrules = []
endfunction




function! panacea#define_default_rules()  "{{{2
  " urules  "{{{
  let urules = {}
  let urules.names = []
  let urules.table = {}
  let lc_alphabet = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z']
  let uc_alphabet = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z']
  let digits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']
  function! urules.add(name, urules)
    call add(self.names, a:name)
    let self.table[a:name] = a:urules
  endfunction
"  backspacing both parentheses away typically does more harm than good
"  \   {'at': '()\%#', 'char': '<BS>', 'input': '<BS><BS>'},
"  \   {'at': '\%#\s*)', 'char': ')', 'input': '<C-r>=panacea#_leave_block('')'')<Enter><Right>'},
  call urules.add('()', [
  \   {'at': '\%#', 'char': '(', 'input': '()<Left>'},
  \   {'at': '(\%#)', 'char': '<BS>', 'input': '<BS><Del>'},
  \   {'at': '\\\%#', 'char': '(', 'input': '('},
  \   {'at': '(\%#)', 'char': '<Enter>', 'input': '<Enter><Esc>"_O'},
  \   {'at': '(\n\t*\%#\n\t*)', 'char': '<BS>', 'input': '<Esc>dd:left<CR>i<BS>'},
  \ ])
  "\   {'at': '\%#\_s*)', 'char': ')', 'input': '<C-r>=panacea#_leave_block('')'')<Enter><Right>'},
  "\   {'at': '(\%#)', 'char': '<Enter>', 'input': '<Enter><Enter><BS><Up><Esc>"_A'},
"  backspacing both parentheses away typically does more harm than good
"  \   {'at': '\[\]\%#', 'char': '<BS>', 'input': '<BS><BS>'},
  call urules.add('[]', [
  \   {'at': '\%#', 'char': '[', 'input': '[]<Left>'},
  \   {'at': '\[\%#\]', 'char': '<BS>', 'input': '<BS><Del>'},
  \   {'at': '\\\%#', 'char': '[', 'input': '['},
  \   {'at': '\[\%#\]', 'char': '<Enter>', 'input': '<Enter><Esc>"_O'},
  \   {'at': '\[\n\t*\%#\n\t*\]', 'char': '<BS>', 'input': '<Esc>dd:left<CR>i<BS>'},
  \   {'at': '^\s*\S\+\%#\S*,$', 'char': '<Enter>', 'input': '<Esc>o,<Left>'},
  \ ])
  "\   {'at': '\%#\_s*\]', 'char': ']', 'input': '<C-r>=panacea#_leave_block('']'')<Enter><Right>'},
"  backspacing both parentheses away typically does more harm than good
"  \   {'at': '{}\%#', 'char': '<BS>', 'input': '<BS><BS>'},
  call urules.add('{}', [
  \   {'at': '\%#', 'char': '{', 'input': '{}<Left>'},
  \   {'at': '{\%#}', 'char': '<BS>', 'input': '<BS><Del>'},
  \   {'at': '\\\%#', 'char': '{', 'input': '{'},
  \   {'at': '{\%#}', 'char': '<Enter>', 'input': '<Enter><Esc>"_O'},
  \   {'at': '{\n\t*\%#\n\t*}', 'char': '<BS>', 'input': '<Esc>dd:left<CR>i<BS>'},
  \ ])
  " Rules for escaping out of current block/string/list
  " These are more aggressive than the original versions I removed
  call urules.add('Escape patterns', [
  \   {'at': '\%#[^)]*)', 'char': ')', 'input': '<C-r>=panacea#_leave_block('')'')<Enter><Right>'},
  \   {'at': '\%#[^\]]*\]', 'char': ']', 'input': '<C-r>=panacea#_leave_block('']'')<Enter><Right>'},
  \   {'at': '\%#[^}]*}', 'char': '}', 'input': '<C-r>=panacea#_leave_block(''}'')<Enter><Right>'},
  \   {'at': '\%#[^"]*"', 'char': '"', 'input': '<C-r>=panacea#_leave_block(''"'')<Enter><Right>'},
  \   {'at': '\\\%#[^"]*"', 'char': '"', 'input': '"'},
  \   {'at': '\%#[^'']*''', 'char': '''', 'input': '<C-r>=panacea#_leave_block('''''''')<Enter><Right>'},
  \   {'at': '\\\%#[^'']*''', 'char': '''', 'input': ''''},
  \ ])
  " Basic patterns should be supported by all languages (including bash)
  " 1: clean lagging space
  " 2: prevent multiple spaces in a row
  " 3-6: maintain space equilibrium
  " 7: space after comma
  call urules.add('Basic patterns', [
  \   {'at': ',\s\%#$', 'char': '<Enter>', 'input': '<Esc>Da<Enter>'},
  \   {'at': '[,-=] \%#', 'char': '<Space>', 'input': ''},
  \   {'at': '{\%#}', 'char': '<Space>', 'input': '<Space><Space><Left>'},
  \   {'at': '(\%#)', 'char': '<Space>', 'input': '<Space><Space><Left>'},
  \   {'at': '\[\%#\]', 'char': '<Space>', 'input': '<Space><Space><Left>'},
  \   {'at': '{\s\%#\s}', 'char': '<BS>', 'input': '<BS><Del>'},
  \   {'at': '(\s\%#\s)', 'char': '<BS>', 'input': '<BS><Del>'},
  \   {'at': '\[\s\%#\s\]', 'char': '<BS>', 'input': '<BS><Del>'},
  \   {'at': '[A-Za-z0-9_]\%#', 'char': ',', 'input': ', '},
  \ ])
  " Common patterns should be supported by most, but may break some arcane
  " langauges like bash
  " 1: prettify assignment
  call urules.add('Common patterns', [
  \   {'at': '^\s*[A-Za-z0-9_.$]\+\%#', 'char': '=', 'input': ' = '},
  \ ])
  call urules.add('C blocks', [
  \   {'at': '=[^>][^)]*{\%#}$', 'char': '<Enter>', 'input': '<Enter><End>;<Esc>"_O'},
  \   {'at': '=[^>][^)]*(\%#)$', 'char': '<Enter>', 'input': '<Enter><End>;<Esc>"_O'},
  \   {'at': '=[^>][^)]*\[\%#\]$', 'char': '<Enter>', 'input': '<Enter><End>;<Esc>"_O'},
  \   {'at': '^\_s*return .*{\%#}$', 'char': '<Enter>', 'input': '<Enter><End>;<Esc>"_O'},
  \   {'at': '(.*{\%#})$', 'char': '<Enter>', 'input': '<Enter><End>;<Esc>"_O'},
  \   {'at': '^\s*[A-Za-z_][A-Za-z0-9_.]*\%#$', 'char': '(', 'input': '();<Left><Left>'},
  \   {'at': '\%#[,;]', 'char': ';', 'input': '<Del>;'},
  \   {'at': '\%#[,;]', 'char': ',', 'input': '<Del>,'},
  \   {'at': '=\%#$', 'char': '<Space>', 'input': '<Space>;<Left>'},
  \   {'at': '^\s*return\%#$', 'char': '<Space>', 'input': '<Space>;<Left>'},
  \ ])
  " I tend to use Python/RapydScript more, this is to do the right thing in JS
  " even when my muscle memory does the wrong thing
  call urules.add('JS macro', [
  \   {'at': '^\_s*\%#', 'char': '#', 'input': '// '},
  \ ])
  " since I use awesome WM and Hammerspoon, I have to use lua more often than
  " I'd like, these help me with common macros so it's less painful
  call urules.add('Lua macros', [
  \   {'at': '^\_s*\%#', 'char': '#', 'input': '-- '},
  \   {'at': '^\s*if\%#$', 'char': '<Space>', 'input': ' end<Esc>gea '},
  \   {'at': '\sfunction\%#', 'char': '<Space>', 'input': ' () end<Esc>gea'},
  \   {'at': '\%#\s*end', 'char': '<Enter>', 'input': '<Esc><Right>dtei<Enter><Esc>O'},
  \ ])
"  Convenience macros for markdown
"  1-6: list manipulation
"  7-9: punctuation handling in sentences
"  \   {'at': '^\_s*-.*\%#', 'char': '<Enter>', 'input': '<Enter><BS><BS>-<Space>'},
  let md_rules = [
  \   {'at': '^\s*\%#$', 'char': '-', 'input': '- '},
  \   {'at': '^\s*- \%#$', 'char': '-', 'input': '<BS>-'},
  \   {'at': '^\s*- \%#$', 'char': ' ', 'input': ''},
  \   {'at': '^\s*- \%#$', 'char': '<Tab>', 'input': '<Esc>>>A '},
  \   {'at': '^\s*- \%#$', 'char': '<S-Tab>', 'input': '<Esc><<A '},
  \   {'at': '^\s*- \%#$', 'char': '<Enter>', 'input': '<BS><BS><Enter>'},
  \   {'at': '^[A-Za-z0-9_].*\%#$', 'char': '.', 'input': '. '},
  \   {'at': '^[A-Za-z0-9_].*\%#$', 'char': '?', 'input': '? '},
  \ ]
  " alphabet capitalization (lookout Clippy!)
  for i in lc_alphabet
      call add(md_rules, {'at': '^\%#$', 'char': i, 'input': i . '<Esc>gUwa'})
      call add(md_rules, {'at': '[.?!] *\%#$', 'char': i, 'input': i . '<Esc>gUwa'})
  endfor
  call urules.add('markdown macro', md_rules)
"  \   {'at': '(.*{\%#})', 'char': '<Enter>', 'input': '<Enter><Enter><BS><End><Up><Esc>"_A'},
"  \   {'at': '(.*{\%#})$', 'char': '<Enter>', 'input': '<Enter><Enter><BS><End>;<Up><Esc>"_A'},
  call urules.add('Perl blocks', [
  \   {'at': '=>.*{\%#}$', 'char': '<Enter>', 'input': '<Enter><End>,<Esc>"_O'},
  \   {'at': '=>.*(\%#)$', 'char': '<Enter>', 'input': '<Enter><End>,<Esc>"_O'},
  \   {'at': '=>.*\[\%#\]$', 'char': '<Enter>', 'input': '<Enter><End>,<Esc>"_O'},
  \   {'at': '=>\%#$', 'char': '<Space>', 'input': '<Space>,<Left>'},
  \ ])
"  \   {'at': '^\s*def\%#$', 'char': '<Space>', 'input': '<Space>:<Left>'},
  call urules.add('Python blocks', [
  \   {'at': '\%#:$', 'char': ':', 'input': '<Right>'},
  \   {'at': '(.\+\%#[''"]\?):\?$', 'char': '<Enter>', 'input': '<Esc>o'},
  \   {'at': '^\s\+\%#', 'char': '#', 'input': '# '},
  \ ])
  " macros for RS, mostly for def completions/expansions
  let rs_rules = [
  \   {'at': '[^A-Za-z0-9_]def\%#$', 'char': '(', 'input': '():<Left><Left>'},
  \   {'at': '[^A-Za-z0-9_]def\%#.\+$', 'char': '(', 'input': '(): ;<Left><Left><Left><Left>'},
  \   {'at': '[^A-Za-z0-9_]def(\(.*[^,]\)\?\%#):', 'char': ':', 'input': '<Right><Right><Right>'},
  \   {'at': '[^A-Za-z0-9_]def\(\s[A-Za-z0-9_$]\+\)(\(.*[^,]\)\?\%#):$', 'char': '<Enter>', 'input': '<Right><Right><Enter>'},
  \   {'at': '[^A-Za-z0-9_]def(\(.*[^,]\)\?\%#):\s;', 'char': '<Enter>', 'input': '<Right><Right><Right><BS><Del><Enter><Esc>O'},
  \   {'at': '[^A-Za-z0-9_]def(\(.*[^,]\)\?):\s\%#;', 'char': '<Enter>', 'input': '<BS><Del><Enter><Esc>O'},
  \ ]
  " code conventions
  for i in lc_alphabet
	  " capitalize class names
      call add(rs_rules, {'at': '^\s*class \%#$', 'char': i, 'input': i . '<Esc>gUwa'})
  endfor
  call urules.add('RapydScript blocks', rs_rules)
  " enforce camel-case
  let camelcase_rules = []
  for i in lc_alphabet
      call add(camelcase_rules, {'at': '[a-z0-9]_\%#$', 'char': i, 'input': i . '<Esc>gUwi<BS><Right>'})
  endfor
  call urules.add('camelCase', camelcase_rules)
  " enforce snake-case
  let snake_rules = []
  for i in uc_alphabet
      call add(snake_rules, {'at': '[a-z0-9]\%#$', 'char': i, 'input': '_'.i.'<Esc>guwa'})
  endfor
  call urules.add('snake_case', snake_rules)
  "\   {'at': '\%#\_s*}', 'char': '}', 'input': '<C-r>=panacea#_leave_block(''}'')<Enter><Right>'},
  "\   {'at': '(.*{\%#})', 'char': '<Enter>', 'input': '<Enter><Enter><BS><Up><Esc>"_A'},
"  backspacing both quotes away typically does more harm than good
"  \   {'at': '''''\%#', 'char': '<BS>', 'input': '<BS><BS>'},
  call urules.add('''''', [
  \   {'at': '\%#', 'char': '''', 'input': '''''<Left>'},
  \   {'at': '\%#''\ze', 'char': '''', 'input': '<Right>'},
  \   {'at': '''\%#''', 'char': '<BS>', 'input': '<BS><Del>'},
  \   {'at': '\\\%#\ze', 'char': '''', 'input': ''''},
  \ ])
  " Though strong quote is a useful feature and it is supported in several
  " languages, \ is usually used to escape next charcters in most languages.
  " So that rules for strong quote are written as additional ones for specific
  " 'filetype's which override the default behavior.
  call urules.add(''''' as strong quote', [
  \   {'at': '\%#''', 'char': '''', 'input': '<Right>'},
  \ ])
  call urules.add('''''''', [
  \   {'at': '''''\%#', 'char': '''', 'input': '''''''''<Left><Left><Left>'},
  \   {'at': '\%#''''''\ze', 'char': '''', 'input': '<Right><Right><Right>'},
  \   {'at': '''''''\%#''''''', 'char': '<BS>', 'input': '<BS><BS><BS><Del><Del><Del>'},
  \   {'at': '''''''''''''\%#', 'char': '<BS>', 'input': '<BS><BS><BS><BS><BS><BS>'},
  \ ])
"  backspacing both quotes away typically does more harm than good
"  \   {'at': '""\%#', 'char': '<BS>', 'input': '<BS><BS>'},
  call urules.add('""', [
  \   {'at': '\%#', 'char': '"', 'input': '""<Left>'},
  \   {'at': '\%#"', 'char': '"', 'input': '<Right>'},
  \   {'at': '"\%#"', 'char': '<BS>', 'input': '<BS><Del>'},
  \   {'at': '\\\%#', 'char': '"', 'input': '"'},
  \ ])
  call urules.add('"""', [
  \   {'at': '""\%#', 'char': '"', 'input': '""""<Left><Left><Left>'},
  \   {'at': '\%#"""', 'char': '"', 'input': '<Right><Right><Right>'},
  \   {'at': '"""\%#"""', 'char': '<BS>', 'input': '<BS><BS><BS><Del><Del><Del>'},
  \   {'at': '""""""\%#', 'char': '<BS>', 'input': '<BS><BS><BS><BS><BS><BS>'},
  \ ])
"  backspacing both quotes away typically does more harm than good
"  \   {'at': '``\%#', 'char': '<BS>', 'input': '<BS><BS>'},
  call urules.add('``', [
  \   {'at': '\%#', 'char': '`', 'input': '``<Left>'},
  \   {'at': '\%#`', 'char': '`', 'input': '<Right>'},
  \   {'at': '`\%#`', 'char': '<BS>', 'input': '<BS><Del>'},
  \   {'at': '\\\%#', 'char': '`', 'input': '`'},
  \ ])
  call urules.add('```', [
  \   {'at': '``\%#', 'char': '`', 'input': '````<Left><Left><Left>'},
  \   {'at': '\%#```', 'char': '`', 'input': '<Right><Right><Right>'},
  \   {'at': '```\%#```', 'char': '<BS>', 'input': '<BS><BS><BS><Del><Del><Del>'},
  \   {'at': '``````\%#', 'char': '<BS>', 'input': '<BS><BS><BS><BS><BS><BS>'},
  \ ])
  call urules.add('English', [
  \   {'at': '\w\%#', 'char': '''', 'input': ''''},
  \ ])
  call urules.add('Lisp quote', [
  \   {'at': '\%#', 'char': '''', 'input': ''''},
  \   {'at': '\%#', 'char': '''', 'input': '''''<Left>',
  \    'syntax': ['Constant']},
  \ ])
  " Unfortunately, the space beyond the end of a comment line is not
  " highlighted as 'Comment'.  So that it is necessary to define one more rule
  " to cover the edge case with only 'at'.
  call urules.add('Python string', [
  \   {'at': '\v\c<([bu]|[bu]?r)>%#', 'char': '''', 'input': '''''<Left>'},
  \   {'at': '\v\c<([bu]|[bu]?r)>%#', 'char': '''', 'input': '''',
  \    'syntax': ['Comment', 'Constant']},
  \   {'at': '\v\c\#.*<([bu]|[bu]?r)>%#$', 'char': '''', 'input': ''''},
  \ ])
  call urules.add('Vim script comment', [
  \   {'at': '^\s*\%#', 'char': '"', 'input': '"'},
  \ ])
  "}}}
"  autocmd FileType perl call panacea#perl_define_default_rules(urules)

  " ft_urule_sets_table... "{{{
  let ft_urule_sets_table = {
  \   '*': [
  \     urules.table['()'],
  \     urules.table['[]'],
  \     urules.table['{}'],
  \     urules.table[''''''],
  \     urules.table[''''''''],
  \     urules.table['""'],
  \     urules.table['"""'],
  \     urules.table['``'],
  \     urules.table['```'],
  \     urules.table['English'],
  \     urules.table['Basic patterns'],
  \   ],
  \   'clojure': [
  \     urules.table['Lisp quote'],
  \   ],
  \   'csh': [
  \     urules.table[''''' as strong quote'],
  \   ],
  \   'java': [
  \     urules.table['C blocks'],
  \     urules.table['Common patterns'],
  \     urules.table['Escape patterns'],
  \     urules.table['camelCase'],
  \   ],
  \   'javascript': [
  \     urules.table[''''' as strong quote'],
  \     urules.table['C blocks'],
  \     urules.table['JS macro'],
  \     urules.table['Common patterns'],
  \     urules.table['Escape patterns'],
  \     urules.table['camelCase'],
  \   ],
  \   'lisp': [
  \     urules.table['Lisp quote'],
  \   ],
  \   'lua': [
  \     urules.table['Lua macros'],
  \     urules.table['Common patterns'],
  \     urules.table['Escape patterns'],
  \     urules.table['snake_case'],
  \   ],
  \   'vimwiki': [
  \     urules.table['markdown macro'],
  \   ],
  \   'vimwiki_markdown': [
  \     urules.table['markdown macro'],
  \   ],
  \   'markdown': [
  \     urules.table['markdown macro'],
  \   ],
  \   'perl': [
  \     urules.table[''''' as strong quote'],
  \     urules.table['C blocks'],
  \     urules.table['Perl blocks'],
  \     urules.table['Common patterns'],
  \     urules.table['Escape patterns'],
  \   ],
  \   'python': [
  \     urules.table['Python blocks'],
  \     urules.table['Python string'],
  \     urules.table['Common patterns'],
  \     urules.table['Escape patterns'],
  \     urules.table['snake_case'],
  \   ],
  \   'rapydscript': [
  \     urules.table['Python blocks'],
  \     urules.table['Python string'],
  \     urules.table['RapydScript blocks'],
  \     urules.table['Common patterns'],
  \     urules.table['Escape patterns'],
  \     urules.table['camelCase'],
  \   ],
  \   'ruby': [
  \     urules.table[''''' as strong quote'],
  \     urules.table['Common patterns'],
  \     urules.table['Escape patterns'],
  \     urules.table['snake_case'],
  \   ],
  \   'scheme': [
  \     urules.table['Lisp quote'],
  \   ],
  \   'sh': [
  \     urules.table[''''' as strong quote'],
  \     urules.table['snake_case'],
  \   ],
  \   'tcsh': [
  \     urules.table[''''' as strong quote'],
  \   ],
  \   'vim': [
  \     urules.table[''''' as strong quote'],
  \     urules.table['Vim script comment'],
  \     urules.table['Common patterns'],
  \   ],
  \   'zsh': [
  \     urules.table[''''' as strong quote'],
  \   ],
  \ }
  "}}}

  for urule_set in ft_urule_sets_table['*']
    for urule in urule_set
      call panacea#define_rule(urule)
    endfor
  endfor

  let overlaid_urules = {}
  let overlaid_urules.pairs = []  " [(URule, [FileType])]
  function! overlaid_urules.add(urule, ft)
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
        call overlaid_urules.add(urule, ft)
      endfor
    endfor
  endfor
  for [urule, fts] in overlaid_urules.pairs
    let completed_urule = copy(urule)
    let completed_urule.filetype = fts
    call panacea#define_rule(completed_urule)
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

function! panacea#_leave_block(end_char)
  " NB: Originally <C-o> was used to execute search(), but <C-o> in
  " Visual-block Insert acts as if <Esc>a, so visually selected lines will be
  " updated and the current mode will be shifted to Insert mode.  It means
  " that there is no timing to execute a Normal mode command.  Therefore we
  " have to use <C-r>= instead.
  call search(a:end_char, 'cW')
  return ''
endfunction




function! panacea#define_rule(urule)  "{{{2
  let nrule = s:normalize_rule(a:urule)
  call s:insert_or_replace_a_rule(s:available_nrules, nrule)
endfunction




function! panacea#map_to_trigger(mode, lhs, rhs_char, rhs_fallback)  "{{{2
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
  execute printf('%snoremap %s %s  <SID>_trigger_or_fallback(%s, %s)',
  \              a:mode,
  \              '<script> <expr>',
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
  let nrule =
  \ mode() =~# '\v^(i|R|Rv)$'
  \ ? s:find_the_most_proper_rule_in_insert_mode(
  \     s:available_nrules,
  \     a:char
  \   )
  \ : s:find_the_most_proper_rule_in_command_line_mode(
  \     s:available_nrules,
  \     a:char,
  \     getcmdline(),
  \     getcmdpos(),
  \     getcmdtype()
  \   )
  if nrule is 0
    return a:fallback
  else
    return nrule._input
  endif
endfunction




function! panacea#map_trigger_keys(...)  "{{{2
  let overridep = 1 <= a:0 ? a:1 : 0

  let d = {'i': {}, 'c': {}}
  for nrule in s:available_nrules
    let char = nrule.char
    if nrule.mode =~# 'i'
      let d['i'][char] = char
    endif
    if nrule.mode =~# '[^i]'
      let d['c'][char] = char
    endif
  endfor

  let M = function('panacea#map_to_trigger')
  let map_modifier = overridep ? '' : '<unique>'
  for mode in keys(d)
    let unique_chars = keys(d[mode])
    for char in unique_chars
      " Do not override existing key mappings.
      silent! call M(mode, map_modifier.' '.char, char, char)
    endfor
  endfor

  for mode in ['i', 'c']
    silent! call M(mode, map_modifier.' '.'<C-h>', '<BS>', '<C-h>')
    silent! call M(mode, map_modifier.' '.'<Return>', '<Enter>', '<Return>')
    silent! call M(mode, map_modifier.' '.'<C-m>', '<Enter>', '<C-m>')
    silent! call M(mode, map_modifier.' '.'<CR>', '<Enter>', '<CR>')
    silent! call M(mode, map_modifier.' '.'<C-j>', '<Enter>', '<C-j>')
    silent! call M(mode, map_modifier.' '.'<NL>', '<Enter>', '<NL>')
  endfor
endfunction




"{{{2




" Misc.  "{{{1
function! panacea#invoke_the_initial_setup_if_necessary()  "{{{2
  " The initial setup is invoked implicitly by :source'ing the autoload file.
  " So that this function does nothing explicitly.
endfunction




function! panacea#scope()  "{{{2
  return s:
endfunction




function! panacea#sid()  "{{{2
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




function! s:find_the_most_proper_rule_in_command_line_mode(nrules, char, cl_text, cl_column, cl_type)  "{{{2
  " FIXME: Optimize for speed if necessary.

  let column = a:cl_column - 1
  let cl_text = (column == 0 ? '' : a:cl_text[:(column - 1)])
  \             . s:UNTYPABLE_CHAR
  \             . a:cl_text[(column):]

  for nrule in a:nrules
    if stridx(nrule.mode, a:cl_type) == -1
      continue
    endif

    if !(a:char ==# nrule._char)
      continue
    endif

    " FIXME: Replace \%# correctly.
    " For example, if nrule.at is '\\%#', it should not be replaced.
    if cl_text !~# substitute(nrule.at, '\\%#', s:UNTYPABLE_CHAR, 'g')
      continue
    endif

    return nrule
  endfor

  return 0
endfunction

let s:UNTYPABLE_CHAR = "\x01"  " FIXME: Use a more proper value.




function! s:find_the_most_proper_rule_in_insert_mode(nrules, char)  "{{{2

  if exists('g:panacea_avoid_autocomplete_collisions') && pumvisible() && g:panacea_avoid_autocomplete_collisions == a:char
    return 0
  endif

  " FIXME: Optimize for speed if necessary.
  let syntax_names = map(synstack(line('.'), col('.')),
  \                      'synIDattr(synIDtrans(v:val), "name")')

  for nrule in a:nrules
    if stridx(nrule.mode, 'i') == -1
      continue
    endif

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
  return substitute(panacea#sid(), '<SNR>', "\<SNR>", 'g')
endfunction




"{{{2




" The initial setup  "{{{1
function! s:do_initial_setup()  "{{{2
  call panacea#define_default_rules()

  if !exists('g:panacea_no_default_key_mappings')
    call panacea#map_trigger_keys()
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
