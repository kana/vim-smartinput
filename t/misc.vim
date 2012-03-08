runtime! plugin/smartinput.vim

call vspec#hint({'scope': 'smartinput#scope()', 'sid': 'smartinput#sid()'})
syntax enable
set backspace=indent,eol,start

describe 's:calculate_rule_priority'
  it 'should use "at", "mode", "filetype" and "syntax"'
    let snrule1 = {
    \   'at': '\%#',
    \   'char': '(',
    \   'input': '()<Left>',
    \   'mode': 'i',
    \   'filetype': ['foo', 'bar', 'baz'],
    \   'syntax': ['String', 'Comment'],
    \ }
    Expect Call('s:calculate_rule_priority', snrule1)
    \      == 3 + 100 / 3 + 100 / 2 + 100 / 1

    let snrule2 = {
    \   'at': '\%#',
    \   'char': '[',
    \   'input': '[  ]<Left><Left>',
    \   'mode': 'i',
    \   'filetype': ['foo', 'bar', 'baz'],
    \   'syntax': ['String', 'Comment'],
    \ }
    Expect Call('s:calculate_rule_priority', snrule2)
    \      == 3 + 100 / 3 + 100 / 2 + 100 / 1

    let snrule3 = {
    \   'at': '\%#',
    \   'char': '(',
    \   'input': '<Bslash>(',
    \   'mode': '/?',
    \   'filetype': 0,
    \   'syntax': 0,
    \ }
    Expect Call('s:calculate_rule_priority', snrule3)
    \      == 3 + 0 + 0 + 100 / 2
  end

  it 'should use a low value for omitted "filetype" and "syntax"'
    let snrule = {
    \   'at': '\%#',
    \   'char': '(',
    \   'input': '()<Left>',
    \   'mode': 'i',
    \   'filetype': 0,
    \   'syntax': 0,
    \ }
    Expect Call('s:calculate_rule_priority', snrule)
    \      == 3 + 0 + 0 + 100 / 1
  end
end

describe 's:decode_key_notation'
  it 'should decode a <Key> notation into an actual byte sequence'
    Expect Call('s:decode_key_notation', 'foo') ==# "foo"
    Expect Call('s:decode_key_notation', '"') ==# "\""
    Expect Call('s:decode_key_notation', '\') ==# "\\"
    Expect Call('s:decode_key_notation', '<C-h>') ==# "\<C-h>"
    Expect Call('s:decode_key_notation', '<BS>') ==# "\<BS>"
    Expect Call('s:decode_key_notation', '<LT><LT>') ==# "\<LT>\<LT>"
  end
end

describe 's:find_the_most_proper_rule_in_command_line_mode'
  before
    new
    let b:nrule1 = Call('s:normalize_rule', {
    \   'at': '\%#',
    \   'char': '<LT>',
    \   'input': '<LT>><Left>',
    \   'mode': ':',
    \ })
    let b:nrule2 = Call('s:normalize_rule', {
    \   'at': '\w\%#',
    \   'char': '<LT>',
    \   'input': '<LT>',
    \   'mode': ':',
    \ })
    let b:nrule3 = Call('s:normalize_rule', {
    \   'at': '\%#',
    \   'char': '<LT>',
    \   'input': '<LT>',
    \   'filetype': ['lisp', 'scheme'],
    \   'mode': '/',
    \ })
    let b:nrule4 = Call('s:normalize_rule', {
    \   'at': '\%#',
    \   'char': '<LT>',
    \   'input': '<LT>><Left>',
    \   'filetype': ['lisp', 'scheme'],
    \   'syntax': ['Comment', 'String'],
    \   'mode': '/',
    \ })
    let b:nrule5 = Call('s:normalize_rule', {
    \   'at': '\%#',
    \   'char': '<LT>',
    \   'input': 'This rule MUST NOT be selected.',
    \   'mode': 'i',
    \ })
    let b:nrules = [b:nrule5, b:nrule4, b:nrule3, b:nrule2, b:nrule1]

    function! b:find(...)
      return call('Call',
      \           ['s:find_the_most_proper_rule_in_command_line_mode'] + a:000)
    endfunction
  end

  after
    close!
  end

  it 'should fail if there is no rule for a given char'
    Expect b:find(b:nrules, '[', '', 1, ':') ==# 0
  end

  it 'should fail if there is no rule for a given command-line type'
    Expect b:find(b:nrules, '<', '', 1, 'X') ==# 0
  end

  it 'should check the text under the cursor by "at"'
    " foo #bar
    Expect b:find(b:nrules, '<', 'foo bar', 5, ':') ==# b:nrule1

    " foo# bar
    Expect b:find(b:nrules, '<', 'foo bar', 4, ':') ==# b:nrule2
  end

  it 'should ignore "filetype" and "syntax"'
    setfiletype scheme

    " foo #bar
    Expect b:find(b:nrules, '<', 'foo bar', 5, '/') ==# b:nrule4
  end
end

describe 's:find_the_most_proper_rule_in_insert_mode'
  before
    new
    let b:nrule1 = Call('s:normalize_rule', {
    \   'at': '\%#',
    \   'char': '<LT>',
    \   'input': '<LT>><Left>',
    \ })
    let b:nrule2 = Call('s:normalize_rule', {
    \   'at': '\w\%#',
    \   'char': '<LT>',
    \   'input': '<LT>',
    \ })
    let b:nrule3 = Call('s:normalize_rule', {
    \   'at': '\%#',
    \   'char': '<LT>',
    \   'input': '<LT>',
    \   'filetype': ['lisp', 'scheme'],
    \ })
    let b:nrule4 = Call('s:normalize_rule', {
    \   'at': '\%#',
    \   'char': '<LT>',
    \   'input': '<LT>><Left>',
    \   'filetype': ['lisp', 'scheme'],
    \   'syntax': ['Comment', 'String'],
    \ })
    let b:nrule5 = Call('s:normalize_rule', {
    \   'at': '\%#',
    \   'char': '<LT>',
    \   'input': 'This rule MUST NOT be selected.',
    \   'mode': ':',
    \ })
    let b:nrules = [b:nrule5, b:nrule4, b:nrule3, b:nrule2, b:nrule1]

    function! b:find(...)
      return call('Call',
      \           ['s:find_the_most_proper_rule_in_insert_mode'] + a:000)
    endfunction
  end

  after
    close!
  end

  it 'should fail if there is no rule for a given char'
    Expect b:find(b:nrules, '[') ==# 0
  end

  it 'should check the text under the cursor by "at"'
    setfiletype html
    call setline(1, '(define foo )  ; ...')
    Expect getline(1, line('$')) ==# ['(define foo )  ; ...']

    " (define foo #)  ; ...
    normal! ggf)
    Expect [line('.'), col('.')] ==# [1, 13]
    Expect b:find(b:nrules, '<') ==# b:nrule1

    " (define foo# )  ; ...
    normal! ggf)h
    Expect [line('.'), col('.')] ==# [1, 12]
    Expect b:find(b:nrules, '<') ==# b:nrule2
  end

  it 'should check the filetype of the current buffer with "filetype"'
    setfiletype scheme
    call setline(1, '(define foo )  ; ...')
    Expect getline(1, line('$')) ==# ['(define foo )  ; ...']

    " (define foo #)  ; ...
    normal! ggf)
    Expect [line('.'), col('.')] ==# [1, 13]
    Expect b:find(b:nrules, '<') ==# b:nrule3

    " (define foo# )  ; ...
    normal! ggf)h
    Expect [line('.'), col('.')] ==# [1, 12]
    Expect b:find(b:nrules, '<') ==# b:nrule3
  end

  it 'should check the syntax name of text under the cursor with "syntax"'
    setfiletype scheme
    call setline(1, '(define foo )  ; ...')
    Expect getline(1, line('$')) ==# ['(define foo )  ; ...']

    " (define foo #)  ; ...
    normal! ggf)
    Expect [line('.'), col('.')] ==# [1, 13]
    Expect b:find(b:nrules, '<') ==# b:nrule3

    " (define foo )  ; #...
    normal! ggf.
    Expect [line('.'), col('.')] ==# [1, 18]
    Expect b:find(b:nrules, '<') ==# b:nrule4
  end
end

describe 's:insert_or_replace_a_rule'
  before
    new

    let b:nrule_table = {}
    for char in ['A', 'B', 'C', 'D', 'E', 'F']
      let b:nrule_table[char] = Call('s:normalize_rule', {
      \   'at': '---',
      \   'char': char,
      \   'input': '---',
      \ })
    endfor

    let b:sorted_nrules =
    \ map(
    \   reverse(sort(map(values(b:nrule_table), '[v:val.hash, v:val]'))),
    \   'v:val[1]'
    \ )
  end

  after
    close
  end

  it 'should replace an existing value which is equivalent to the given one'
    let nrule_table = {}
    for char in ['A', 'B', 'C', 'D', 'E', 'F']
      let nrule_table[char] = Call('s:normalize_rule', {
      \   'at': '---',
      \   'char': char,
      \   'input': '===',
      \ })
    endfor

    Expect b:sorted_nrules ==# [
    \   b:nrule_table['F'],
    \   b:nrule_table['E'],
    \   b:nrule_table['D'],
    \   b:nrule_table['C'],
    \   b:nrule_table['B'],
    \   b:nrule_table['A'],
    \ ]

    call Call('s:insert_or_replace_a_rule', b:sorted_nrules, nrule_table['A'])
    Expect b:sorted_nrules ==# [
    \   b:nrule_table['F'],
    \   b:nrule_table['E'],
    \   b:nrule_table['D'],
    \   b:nrule_table['C'],
    \   b:nrule_table['B'],
    \   nrule_table['A'],
    \ ]

    call Call('s:insert_or_replace_a_rule', b:sorted_nrules, nrule_table['B'])
    Expect b:sorted_nrules ==# [
    \   b:nrule_table['F'],
    \   b:nrule_table['E'],
    \   b:nrule_table['D'],
    \   b:nrule_table['C'],
    \   nrule_table['B'],
    \   nrule_table['A'],
    \ ]

    call Call('s:insert_or_replace_a_rule', b:sorted_nrules, nrule_table['C'])
    Expect b:sorted_nrules ==# [
    \   b:nrule_table['F'],
    \   b:nrule_table['E'],
    \   b:nrule_table['D'],
    \   nrule_table['C'],
    \   nrule_table['B'],
    \   nrule_table['A'],
    \ ]

    call Call('s:insert_or_replace_a_rule', b:sorted_nrules, nrule_table['D'])
    Expect b:sorted_nrules ==# [
    \   b:nrule_table['F'],
    \   b:nrule_table['E'],
    \   nrule_table['D'],
    \   nrule_table['C'],
    \   nrule_table['B'],
    \   nrule_table['A'],
    \ ]

    call Call('s:insert_or_replace_a_rule', b:sorted_nrules, nrule_table['E'])
    Expect b:sorted_nrules ==# [
    \   b:nrule_table['F'],
    \   nrule_table['E'],
    \   nrule_table['D'],
    \   nrule_table['C'],
    \   nrule_table['B'],
    \   nrule_table['A'],
    \ ]

    call Call('s:insert_or_replace_a_rule', b:sorted_nrules, nrule_table['F'])
    Expect b:sorted_nrules ==# [
    \   nrule_table['F'],
    \   nrule_table['E'],
    \   nrule_table['D'],
    \   nrule_table['C'],
    \   nrule_table['B'],
    \   nrule_table['A'],
    \ ]
  end

  it 'should insert a given rule into the "sorted" position'
    let nrule_table = {}
    for char in ['00', 'AA', 'BB', 'CC', 'DD', 'EE', 'FF']
      let nrule_table[char] = Call('s:normalize_rule', {
      \   'at': '---',
      \   'char': char,
      \   'input': '===',
      \ })
    endfor

    Expect b:sorted_nrules ==# [
    \   b:nrule_table['F'],
    \   b:nrule_table['E'],
    \   b:nrule_table['D'],
    \   b:nrule_table['C'],
    \   b:nrule_table['B'],
    \   b:nrule_table['A'],
    \ ]

    call Call('s:insert_or_replace_a_rule', b:sorted_nrules, nrule_table['00'])
    Expect b:sorted_nrules ==# [
    \   b:nrule_table['F'],
    \   b:nrule_table['E'],
    \   b:nrule_table['D'],
    \   b:nrule_table['C'],
    \   b:nrule_table['B'],
    \   b:nrule_table['A'],
    \   nrule_table['00'],
    \ ]

    call Call('s:insert_or_replace_a_rule', b:sorted_nrules, nrule_table['AA'])
    Expect b:sorted_nrules ==# [
    \   b:nrule_table['F'],
    \   b:nrule_table['E'],
    \   b:nrule_table['D'],
    \   b:nrule_table['C'],
    \   b:nrule_table['B'],
    \   nrule_table['AA'],
    \   b:nrule_table['A'],
    \   nrule_table['00'],
    \ ]

    call Call('s:insert_or_replace_a_rule', b:sorted_nrules, nrule_table['BB'])
    Expect b:sorted_nrules ==# [
    \   b:nrule_table['F'],
    \   b:nrule_table['E'],
    \   b:nrule_table['D'],
    \   b:nrule_table['C'],
    \   nrule_table['BB'],
    \   b:nrule_table['B'],
    \   nrule_table['AA'],
    \   b:nrule_table['A'],
    \   nrule_table['00'],
    \ ]

    call Call('s:insert_or_replace_a_rule', b:sorted_nrules, nrule_table['CC'])
    Expect b:sorted_nrules ==# [
    \   b:nrule_table['F'],
    \   b:nrule_table['E'],
    \   b:nrule_table['D'],
    \   nrule_table['CC'],
    \   b:nrule_table['C'],
    \   nrule_table['BB'],
    \   b:nrule_table['B'],
    \   nrule_table['AA'],
    \   b:nrule_table['A'],
    \   nrule_table['00'],
    \ ]

    call Call('s:insert_or_replace_a_rule', b:sorted_nrules, nrule_table['DD'])
    Expect b:sorted_nrules ==# [
    \   b:nrule_table['F'],
    \   b:nrule_table['E'],
    \   nrule_table['DD'],
    \   b:nrule_table['D'],
    \   nrule_table['CC'],
    \   b:nrule_table['C'],
    \   nrule_table['BB'],
    \   b:nrule_table['B'],
    \   nrule_table['AA'],
    \   b:nrule_table['A'],
    \   nrule_table['00'],
    \ ]

    call Call('s:insert_or_replace_a_rule', b:sorted_nrules, nrule_table['EE'])
    Expect b:sorted_nrules ==# [
    \   b:nrule_table['F'],
    \   nrule_table['EE'],
    \   b:nrule_table['E'],
    \   nrule_table['DD'],
    \   b:nrule_table['D'],
    \   nrule_table['CC'],
    \   b:nrule_table['C'],
    \   nrule_table['BB'],
    \   b:nrule_table['B'],
    \   nrule_table['AA'],
    \   b:nrule_table['A'],
    \   nrule_table['00'],
    \ ]

    call Call('s:insert_or_replace_a_rule', b:sorted_nrules, nrule_table['FF'])
    Expect b:sorted_nrules ==# [
    \   nrule_table['FF'],
    \   b:nrule_table['F'],
    \   nrule_table['EE'],
    \   b:nrule_table['E'],
    \   nrule_table['DD'],
    \   b:nrule_table['D'],
    \   nrule_table['CC'],
    \   b:nrule_table['C'],
    \   nrule_table['BB'],
    \   b:nrule_table['B'],
    \   nrule_table['AA'],
    \   b:nrule_table['A'],
    \   nrule_table['00'],
    \ ]
  end

  it 'should insert a given rule as the 0th element of an empty list'
    let nrules = []
    Expect nrules ==# []

    call Call('s:insert_or_replace_a_rule', nrules, b:nrule_table['A'])
    Expect nrules ==# [b:nrule_table['A']]
  end
end

describe 's:normalize_rule'
  it 'should copy a given rule recursively'
    let urule = {
    \   'at': '\%#',
    \   'char': '(',
    \   'input': '()<Left>',
    \   'filetype': ['foo', 'bar'],
    \   'syntax': ['String', 'Comment'],
    \ }
    let nrule = Call('s:normalize_rule', urule)

    Expect nrule isnot urule
    Expect nrule.filetype isnot urule.filetype
    Expect nrule.syntax isnot urule.syntax
  end

  it 'should sort "filetype" and "syntax"'
    let urule = {
    \   'at': '\%#',
    \   'char': '(',
    \   'input': '()<Left>',
    \   'filetype': ['foo', 'bar'],
    \   'syntax': ['String', 'Comment'],
    \ }
    let nrule = Call('s:normalize_rule', urule)

    Expect nrule.filetype ==# ['bar', 'foo']
    Expect nrule.syntax ==# ['Comment', 'String']
  end

  it 'should complete optional items'
    let urule = {
    \   'at': '\%#',
    \   'char': '(',
    \   'input': '()<Left>',
    \ }
    let nrule = Call('s:normalize_rule', urule)

    Expect nrule ==# {
    \   'at': urule.at,
    \   'char': urule.char,
    \   '_char': Call('s:decode_key_notation', urule.char),
    \   'input': urule.input,
    \   '_input': Call('s:decode_key_notation', urule.input),
    \   'mode': 'i',
    \   'filetype': 0,
    \   'syntax': 0,
    \   'priority': 3 + 0 + 0 + 100 / 1,
    \   'hash': string([printf('%06d', 3 + 0 + 0 + 100 / 1),
    \                   urule.at,
    \                   urule.char,
    \                   0,
    \                   0]),
    \ }
  end
end
