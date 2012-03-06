" NB: MacVim defines several key mappings such as <D-v> by default.
" The key mappings are defined from the core, not from any runtime file.
" So that the key mappings are always defined even if Vim is invoked by
" "vim -u NONE" etc.  Remove the kay mappings to ensure that there is no key
" mappings, because some tests in this file assume such state.
imapclear

runtime! plugin/smartpunc.vim

call vspec#hint({'scope': 'smartpunc#scope()', 'sid': 'smartpunc#sid()'})
set backspace=indent,eol,start
filetype plugin indent on
syntax enable

describe 'smartpunc#clear_rules'
  before
    SaveContext
    new
    let b:uruleA = {
    \   'at': '\%#',
    \   'char': '(',
    \   'input': '()<Left>',
    \   'filetype': ['foo', 'bar', 'baz'],
    \   'syntax': ['String', 'Comment'],
    \ }
    let b:nruleA = Call('s:normalize_rule', b:uruleA)
    let b:uruleB = {
    \   'at': '\%#',
    \   'char': '[',
    \   'input': '[]<Left>',
    \   'filetype': ['foo', 'bar'],
    \   'syntax': ['String', 'Comment'],
    \ }
    let b:nruleB = Call('s:normalize_rule', b:uruleB)
  end

  after
    close
    ResetContext
  end

  it 'should clear all defined rules'
    " Because of the default configuration.
    Expect Ref('s:available_nrules') !=# []

    call smartpunc#clear_rules()
    Expect Ref('s:available_nrules') ==# []

    call smartpunc#define_rule(b:uruleA)
    Expect Ref('s:available_nrules') ==# [b:nruleA]

    call smartpunc#define_rule(b:uruleB)
    Expect Ref('s:available_nrules') ==# [b:nruleB, b:nruleA]

    call smartpunc#clear_rules()
    Expect Ref('s:available_nrules') ==# []
  end
end

describe 'smartpunc#define_default_rules'
  before
    SaveContext
  end

  after
    ResetContext
  end

  it 'should define many rules'
    call smartpunc#clear_rules()
    Expect Ref('s:available_nrules') ==# []

    call smartpunc#define_default_rules()
    Expect Ref('s:available_nrules') !=# []
  end

  it 'should override existing rules if conflicted'
    call smartpunc#clear_rules()
    Expect Ref('s:available_nrules') ==# []

    call smartpunc#define_rule({'at': 'x\%#', 'char': '(', 'input': '---'})
    call smartpunc#define_rule({'at': '\%#', 'char': '(', 'input': '---'})
    Expect len(Ref('s:available_nrules')) == 2

    let unconflicted_nrule = Ref('s:available_nrules')[0]
    let conflicted_nrule = Ref('s:available_nrules')[1]
    Expect unconflicted_nrule.at ==# 'x\%#'
    Expect conflicted_nrule.at ==# '\%#'

    call smartpunc#define_default_rules()
    Expect Ref('s:available_nrules') !=# []
    Expect index(Ref('s:available_nrules'), unconflicted_nrule) != -1
    Expect index(Ref('s:available_nrules'), conflicted_nrule) == -1
  end

  " The behavior of each rules are tested
  " in 'The default configuration' block.
end

describe 'smartpunc#define_rule'
  before
    SaveContext
    new
    let b:uruleA = {
    \   'at': '\%#',
    \   'char': '(',
    \   'input': '()<Left>',
    \   'filetype': ['foo', 'bar', 'baz'],
    \   'syntax': ['String', 'Comment'],
    \ }
    let b:nruleA = Call('s:normalize_rule', b:uruleA)
    let b:uruleB = {
    \   'at': '\%#',
    \   'char': '[',
    \   'input': '[]<Left>',
    \   'filetype': ['foo', 'bar'],
    \   'syntax': ['String', 'Comment'],
    \ }
    let b:nruleB = Call('s:normalize_rule', b:uruleB)
    let b:uruleBd = {
    \   'at': '\%#',
    \   'char': '[',
    \   'input': '[  ]<Left><Left>',
    \   'filetype': ['foo', 'bar'],
    \   'syntax': ['String', 'Comment'],
    \ }
    let b:nruleBd = Call('s:normalize_rule', b:uruleBd)
    let b:uruleC1 = {
    \   'at': ' + \%#',
    \   'char': '+',
    \   'input': '<BS><BS><BS>++',
    \ }
    let b:nruleC1 = Call('s:normalize_rule', b:uruleC1)
    let b:uruleC2 = {
    \   'at': '\S \%#',
    \   'char': '+',
    \   'input': '+ ',
    \ }
    let b:nruleC2 = Call('s:normalize_rule', b:uruleC2)
  end

  after
    close
    ResetContext
  end

  it 'should define a new rule in the global state'
    " Because of the default configuration.
    Expect Ref('s:available_nrules') !=# []

    call Set('s:available_nrules', [])
    Expect Ref('s:available_nrules') ==# []

    call smartpunc#define_rule(b:uruleA)
    Expect Ref('s:available_nrules') ==# [b:nruleA]

    call smartpunc#define_rule(b:uruleB)
    Expect Ref('s:available_nrules') ==# [b:nruleB, b:nruleA]
  end

  it 'should not define two or more "same" rules'
    " Because of the default configuration.
    Expect Ref('s:available_nrules') !=# []

    call Set('s:available_nrules', [])
    Expect Ref('s:available_nrules') ==# []

    call smartpunc#define_rule(b:uruleA)
    Expect Ref('s:available_nrules') ==# [b:nruleA]

    call smartpunc#define_rule(b:uruleA)
    Expect Ref('s:available_nrules') ==# [b:nruleA]

    call smartpunc#define_rule(b:uruleB)
    Expect Ref('s:available_nrules') ==# [b:nruleB, b:nruleA]

    call smartpunc#define_rule(b:uruleBd)
    Expect Ref('s:available_nrules') ==# [b:nruleBd, b:nruleA]
  end

  it 'should sort defined rules by priority in descending order (1)'
    Expect b:nruleA.priority < b:nruleB.priority

    " Because of the default configuration.
    Expect Ref('s:available_nrules') !=# []

    call Set('s:available_nrules', [])
    Expect Ref('s:available_nrules') ==# []

    call smartpunc#define_rule(b:uruleA)
    call smartpunc#define_rule(b:uruleB)
    Expect Ref('s:available_nrules') ==# [b:nruleB, b:nruleA]

  end

  it 'should sort defined rules by priority in descending order (2)'
    Expect b:nruleA.priority < b:nruleB.priority

    " Because of the default configuration.
    Expect Ref('s:available_nrules') !=# []

    call Set('s:available_nrules', [])
    Expect Ref('s:available_nrules') ==# []

    call smartpunc#define_rule(b:uruleB)
    call smartpunc#define_rule(b:uruleA)
    Expect Ref('s:available_nrules') ==# [b:nruleB, b:nruleA]
  end

  it 'should sort defined rules by "priority" and "at" in descending order (1)'
    Expect b:nruleC1.priority == b:nruleC2.priority
    Expect b:nruleC1.at <# b:nruleC2.at

    " Because of the default configuration.
    Expect Ref('s:available_nrules') !=# []

    call Set('s:available_nrules', [])
    Expect Ref('s:available_nrules') ==# []

    call smartpunc#define_rule(b:uruleC1)
    call smartpunc#define_rule(b:uruleC2)
    Expect Ref('s:available_nrules') ==# [b:nruleC2, b:nruleC1]
  end

  it 'should sort defined rules by "priority" and "at" in descending order (2)'
    Expect b:nruleC1.priority == b:nruleC2.priority
    Expect b:nruleC1.at <# b:nruleC2.at

    " Because of the default configuration.
    Expect Ref('s:available_nrules') !=# []

    call Set('s:available_nrules', [])
    Expect Ref('s:available_nrules') ==# []

    call smartpunc#define_rule(b:uruleC2)
    call smartpunc#define_rule(b:uruleC1)
    Expect Ref('s:available_nrules') ==# [b:nruleC2, b:nruleC1]
  end
end

describe 'smartpunc#map_to_trigger'
  before
    SaveContext
    new

    let M = function('smartpunc#map_to_trigger')

    " With a cursor adjustment.
    call smartpunc#define_rule({
    \   'at': '\%#',
    \   'char': '(',
    \   'input': '()<Left>',
    \ })
    call M('i', '<buffer> (', '(', '(')

    " Without any cursor adjustment.
    call smartpunc#define_rule({
    \   'at': '\%#',
    \   'char': '1',
    \   'input': '123',
    \ })
    call M('i', '<buffer> 1', '1', '1')

    " Failure case - 1.
    " ... no rule is defined for 'x' for intentional failure.
    call M('i', '<buffer> F1', 'x', 'x')

    " Failure case - 2.
    " ... no rule is defined for 'y' for intentional failure.
    call M('i', '<buffer> F2', 'x', 'y')

    " With a special "char".
    call smartpunc#define_rule({
    \   'at': '(\%#)',
    \   'char': '<BS>',
    \   'input': '<BS><Del>',
    \ })
    call M('i', '<buffer> <BS>', '<BS>', '<BS>')

    " With a problematic "char" - ``"''.
    call smartpunc#define_rule({
    \   'at': '\%#',
    \   'char': '"',
    \   'input': '""<Left>',
    \ })
    call M('i', '<buffer> "', '"', '"')

    " With a problematic "char" - ``\''.
    call smartpunc#define_rule({
    \   'at': '\%#',
    \   'char': '<Bslash>',
    \   'input': '<Bslash><Bslash><Left>',
    \ })
    call M('i', '<buffer> <Bslash>', '<Bslash>', '<Bslash>')

    " With automatic indentation.
    call smartpunc#define_rule({
    \   'at': '{\%#}',
    \   'char': '<Return>',
    \   'input': '<Return>*<Return>}<BS><Up><C-o>$<BS>',
    \ })
    call M('i', '<buffer> <Return>', '<Return>', '<Return>')
  end

  after
    close!
    ResetContext
  end

  it 'should do smart input assistant with cursor adjustment properly'
    " "let foo =# "
    call setline(1, 'let foo = ')
    normal! gg$
    Expect getline(1, line('$')) ==# ['let foo = ']
    Expect [line('.'), col('.')] ==# [1, 10]

    " "let foo = (#)" -- invoke at the end of the line.
    execute 'normal' "a("
    Expect getline(1, line('$')) ==# ['let foo = ()']
    Expect [line('.'), col('.')] ==# [1, 12 - 1]

    " "let foo = ((#))" -- invoke at a middle of the line.
    execute 'normal' "a("
    Expect getline(1, line('$')) ==# ['let foo = (())']
    Expect [line('.'), col('.')] ==# [1, 13 - 1]
  end

  it 'should do smart input assistant without cursor adjustment properly'
    " "let foo =# "
    call setline(1, 'let foo = ')
    normal! gg$
    Expect getline(1, line('$')) ==# ['let foo = ']
    Expect [line('.'), col('.')] ==# [1, 10]

    " "let foo = =>>#" -- invoke at the end of the line.
    execute 'normal' "a1"
    Expect getline(1, line('$')) ==# ['let foo = 123']
    Expect [line('.'), col('.')] ==# [1, 14 - 1]

    " "let foo = =>=>>#>" -- invoke at a middle of the line.
    execute 'normal' "i1"
    Expect getline(1, line('$')) ==# ['let foo = 121233']
    Expect [line('.'), col('.')] ==# [1, 16 - 1]
  end

  it 'should insert a fallback char if there is no proper rule (1)'
    " "let foo =# "
    call setline(1, 'let foo = ')
    normal! gg$
    Expect getline(1, line('$')) ==# ['let foo = ']
    Expect [line('.'), col('.')] ==# [1, 10]

    " "let foo = x#" -- invoke at the end of the line.
    execute 'normal' "aF1"
    Expect getline(1, line('$')) ==# ['let foo = x']
    Expect [line('.'), col('.')] ==# [1, 12 - 1]

    " "let foox# = x" -- invoke at a middle of the line.
    execute 'normal' "FoaF1"
    Expect getline(1, line('$')) ==# ['let foox = x']
    Expect [line('.'), col('.')] ==# [1, 9 - 1]
  end

  it 'should insert a fallback char if there is no proper rule (2)'
    " "let foo =# "
    call setline(1, 'let foo = ')
    normal! gg$
    Expect getline(1, line('$')) ==# ['let foo = ']
    Expect [line('.'), col('.')] ==# [1, 10]

    " "let foo = x#" -- invoke at the end of the line.
    execute 'normal' "aF2"
    Expect getline(1, line('$')) ==# ['let foo = y']
    Expect [line('.'), col('.')] ==# [1, 12 - 1]

    " "let foox# = x" -- invoke at a middle of the line.
    execute 'normal' "FoaF2"
    Expect getline(1, line('$')) ==# ['let fooy = y']
    Expect [line('.'), col('.')] ==# [1, 9 - 1]
  end

  it 'should do smart input assistant with a special "char" properly'
    " "let foo = (0#)"
    call setline(1, 'let foo = (0)')
    normal! gg$
    Expect getline(1, line('$')) ==# ['let foo = (0)']
    Expect [line('.'), col('.')] ==# [1, 13]

    " "let foo = (#)"
    execute 'normal' "i\<BS>"
    Expect getline(1, line('$')) ==# ['let foo = ()']
    Expect [line('.'), col('.')] ==# [1, 12 - 1]

    " "let foo = #"
    execute 'normal' "a\<BS>"
    Expect getline(1, line('$')) ==# ['let foo = ']
    Expect [line('.'), col('.')] ==# [1, 11 - 1]
  end

  it 'should do smart input assistant with a problematic "char" - ``"'''''
    " 'let foo = [0, #]'
    call setline(1, 'let foo = [0, ]')
    normal! gg$
    Expect getline(1, line('$')) ==# ['let foo = [0, ]']
    Expect [line('.'), col('.')] ==# [1, 15]

    " 'let foo = [0, "#"]'
    execute 'normal' "i\""
    Expect getline(1, line('$')) ==# ['let foo = [0, ""]']
    Expect [line('.'), col('.')] ==# [1, 16 - 1]
  end

  it 'should do smart input assistant with a problematic "char" - ``\'''''
    " 'let foo = [0, #]'
    call setline(1, 'let foo = [0, ]')
    normal! gg$
    Expect getline(1, line('$')) ==# ['let foo = [0, ]']
    Expect [line('.'), col('.')] ==# [1, 15]

    " 'let foo = [0, \#\]'
    execute 'normal' "i\\"
    Expect getline(1, line('$')) ==# ['let foo = [0, \\]']
    Expect [line('.'), col('.')] ==# [1, 16 - 1]
  end

  it 'should keep automatic indentation'
    setlocal expandtab
    setlocal smartindent

    " 'if (foo) {#}'
    call setline(1, 'if (foo) {}')
    normal! gg$
    Expect getline(1, line('$')) ==# ['if (foo) {}']
    Expect [line('.'), col('.')] ==# [1, 11]

    " 'if (foo) {'
    " '        X#'
    " '}'
    execute 'normal' "i\<Return>X"
    Expect getline(1, line('$')) ==# ['if (foo) {',
    \                                 '        X',
    \                                 '}']
    Expect [line('.'), col('.')] ==# [2, 10 - 1]

    " 'if (foo) {'
    " '        X'
    " '        Y#'
    " '}'
    execute 'normal' "a\<Return>Y"
    Expect getline(1, line('$')) ==# ['if (foo) {',
    \                                 '        X',
    \                                 '        Y',
    \                                 '}']
    Expect [line('.'), col('.')] ==# [3, 10 - 1]

    " 'if (foo) {'
    " '        X'
    " '        Y'
    " ''
    " '        Z#'
    " '}'
    execute 'normal' "a\<Return>\<Return>Z"
    Expect getline(1, line('$')) ==# ['if (foo) {',
    \                                 '        X',
    \                                 '        Y',
    \                                 '',
    \                                 '        Z',
    \                                 '}']
    Expect [line('.'), col('.')] ==# [5, 10 - 1]
  end
end

describe 'The default configuration'
  before
    new

    function! b:.test_rules(test_set_names)
      " NB: [WHAT_MAP_EXPR_CAN_SEE] For some reason, ":normal SLet's" doesn't
      " work as I expected.  When "'" is being inserted with the command,
      " s:_trigger_or_fallback is called with the following context:
      "
      " * getline('.') ==# ''
      " * [line('.'), col('.')] == [1, 1]
      "
      " So that the expected rule ("at" ==# '\w\%#') is NOT selected.
      "
      " But when "'" is being inserted with interactively typed "Let's",
      " s:_trigger_or_fallback is called with the following context:
      "
      " * getline('.') ==# 'Let'
      " * [line('.'), col('.')] == [1, 4]
      "
      " So that the expected rule ("at" ==# '\w\%#') is selected.
      "
      " To avoid the problem, split :normal at the trigger character.
      for test_set in map(copy(a:test_set_names), 'b:test_set_table[v:val]')
        % delete _
        let i = 0  " For debugging.
        for [input, lines, linenr, colnr] in test_set
          let i += 1
          execute 'normal' 'a'.input
          Expect [i, getline(1, line('$'))] ==# [i, lines]
          Expect [i, [line('.'), col('.')]] ==# [i, [linenr, colnr]]
        endfor
      endfor
    endfunction

    let b:test_set_table = {
    \   '""': [
    \     ["\"", ['""'], 1, 2 - 1],
    \     ["\"", ['""'], 1, 3 - 1],
    \     ["\<Left>", ['""'], 1, 2 - 1],
    \     ["\<BS>", [''], 1, 2 - 1],
    \     ["\\", ['\'], 1, 2 - 1],
    \     ["\"", ['\"'], 1, 3 - 1],
    \   ],
    \   '''''': [
    \     ["'", [''''''], 1, 2 - 1],
    \     ["'", [''''''], 1, 3 - 1],
    \     ["\<Left>", [''''''], 1, 2 - 1],
    \     ["\<BS>", [''], 1, 2 - 1],
    \     ["\\", ['\'], 1, 2 - 1],
    \     ["'", ['\'''], 1, 3 - 1],
    \   ],
    \   '()': [
    \     ["(", ['()'], 1, 2 - 1],
    \     [")", ['()'], 1, 3 - 1],
    \     ["\<Left>", ['()'], 1, 2 - 1],
    \     ["\<BS>", [''], 1, 2 - 1],
    \     ["\\", ['\'], 1, 2 - 1],
    \     ["(", ['\('], 1, 3 - 1],
    \   ],
    \   'English': [
    \     ["Let", ['Let'], 1, 4 - 1],
    \     ["'", ['Let'''], 1, 5 - 1],
    \     ["s", ['Let''s'], 1, 6 - 1],
    \     [" ", ['Let''s '], 1, 7 - 1],
    \     ["'", ['Let''s '''''], 1, 8 - 1],
    \     ["quote", ['Let''s ''quote'''], 1, 13 - 1],
    \   ],
    \   '[]': [
    \     ["[", ['[]'], 1, 2 - 1],
    \     ["]", ['[]'], 1, 3 - 1],
    \     ["\<Left>", ['[]'], 1, 2 - 1],
    \     ["\<BS>", [''], 1, 2 - 1],
    \     ["\\", ['\'], 1, 2 - 1],
    \     ["[", ['\['], 1, 3 - 1],
    \   ],
    \   '``': [
    \     ["`", ['``'], 1, 2 - 1],
    \     ["`", ['``'], 1, 3 - 1],
    \     ["\<Left>", ['``'], 1, 2 - 1],
    \     ["\<BS>", [''], 1, 2 - 1],
    \     ["\\", ['\'], 1, 2 - 1],
    \     ["`", ['\`'], 1, 3 - 1],
    \   ],
    \   '{}': [
    \     ["{", ['{}'], 1, 2 - 1],
    \     ["}", ['{}'], 1, 3 - 1],
    \     ["\<Left>", ['{}'], 1, 2 - 1],
    \     ["\<BS>", [''], 1, 2 - 1],
    \     ["\\", ['\'], 1, 2 - 1],
    \     ["{", ['\{'], 1, 3 - 1],
    \   ],
    \ }
  end

  after
    close!
  end

  it 'should define necessary key mappings to trigger smart input assistants'
    redir => s
    0 verbose imap
    redir END
    let lhss = split(s, '\n')
    call map(lhss, 'substitute(v:val, ''\v\S+\s+(\S+)\s+.*'', ''\1'', ''g'')')
    call sort(lhss)

    Expect lhss ==# [
    \   '"',
    \   '''',
    \   '(',
    \   ')',
    \   '<BS>',
    \   '<C-H>',
    \   '<CR>',
    \   '<NL>',
    \   '[',
    \   ']',
    \   '`',
    \   '{',
    \   '}',
    \ ]
  end

  it 'should have generic rules for all filetypes'
    call b:.test_rules([
    \   '()',
    \   '[]',
    \   '{}',
    \   '''''',
    \   '""',
    \   '``',
    \   'English',
    \ ])
  end

  it 'should have rules to write Lisp/Scheme source code'
    " NB: For some reason, :setfiletype doesn't work as I expected.

    function! b:getSynNames(line, col)
      return map(synstack(a:line, a:col),
      \          'synIDattr(synIDtrans(v:val), "name")')
    endfunction

    setlocal filetype=foo
    Expect &l:filetype ==# 'foo'
    normal S(define filetype 'foo
    Expect getline(1, line('$')) ==# ['(define filetype ''foo'')']
    Expect [line('.'), col('.')] ==# [1, 22 - 1]
    Expect b:getSynNames(line('.'), col('.')) ==# []
    normal S(define filetype "'foo
    Expect getline(1, line('$')) ==# ['(define filetype "''foo''")']
    Expect [line('.'), col('.')] ==# [1, 23 - 1]
    Expect b:getSynNames(line('.'), col('.')) ==# []
    normal S; (define filetype 'foo
    Expect getline(1, line('$')) ==# ['; (define filetype ''foo'')']
    Expect [line('.'), col('.')] ==# [1, 24 - 1]
    Expect b:getSynNames(line('.'), col('.')) ==# []

    setlocal filetype=lisp
    Expect &l:filetype ==# 'lisp'
    normal S(define filetype 'lisp
    Expect getline(1, line('$')) ==# ['(define filetype ''lisp)']
    Expect [line('.'), col('.')] ==# [1, 23 - 1]
    Expect b:getSynNames(line('.'), col('.')) ==# ['lispList', 'Identifier']
    normal S(define filetype "'lisp
    Expect getline(1, line('$')) ==# ['(define filetype "''lisp''")']
    Expect [line('.'), col('.')] ==# [1, 24 - 1]
    Expect b:getSynNames(line('.'), col('.')) ==# ['lispList', 'Constant']
    normal S; (define filetype 'lisp
    Expect getline(1, line('$')) ==# ['; (define filetype ''lisp)']
    Expect [line('.'), col('.')] ==# [1, 25 - 1]
    Expect b:getSynNames(line('.'), col('.')) ==# ['Comment']

    setlocal filetype=scheme
    Expect &l:filetype ==# 'scheme'
    normal S(define filetype 'scheme
    Expect getline(1, line('$')) ==# ['(define filetype ''scheme)']
    Expect [line('.'), col('.')] ==# [1, 25 - 1]
    normal S(define filetype "'scheme
    Expect getline(1, line('$')) ==# ['(define filetype "''scheme''")']
    Expect [line('.'), col('.')] ==# [1, 26 - 1]
    Expect b:getSynNames(line('.'), col('.')) ==# ['schemeStruc', 'Constant']
    normal S; (define filetype 'scheme
    Expect getline(1, line('$')) ==# ['; (define filetype ''scheme)']
    Expect [line('.'), col('.')] ==# [1, 27 - 1]
    Expect b:getSynNames(line('.'), col('.')) ==# ['Comment']
  end

  it 'should have rules to write C-like syntax source code'
    setfiletype c
    setlocal expandtab
    Expect &l:filetype ==# 'c'

    for key in ["\<Enter>", "\<Return>", "\<C-m>", "\<CR>", "\<C-j>", "\<C-j>"]
      execute 'normal' printf('ggcGfoo(%sbar,%sbaz', key, key)
      Expect getline(1, line('$')) ==# ['foo(',
      \                                 '                bar,',
      \                                 '                baz',
      \                                 '   )']
      Expect [line('.'), col('.')] ==# [3, 20 - 1]
    endfor
  end
end
