" NB: MacVim defines several key mappings such as <D-v> by default.
" The key mappings are defined from the core, not from any runtime file.
" So that the key mappings are always defined even if Vim is invoked by
" "vim -u NONE" etc.  Remove the kay mappings to ensure that there is no key
" mappings, because some tests in this file assume such state.
imapclear

runtime! plugin/smartinput.vim

call vspec#hint({'scope': 'smartinput#scope()', 'sid': 'smartinput#sid()'})
set backspace=indent,eol,start
filetype plugin indent on
syntax enable

describe 'smartinput#clear_rules'
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

    call smartinput#clear_rules()
    Expect Ref('s:available_nrules') ==# []

    call smartinput#define_rule(b:uruleA)
    Expect Ref('s:available_nrules') ==# [b:nruleA]

    call smartinput#define_rule(b:uruleB)
    Expect Ref('s:available_nrules') ==# [b:nruleB, b:nruleA]

    call smartinput#clear_rules()
    Expect Ref('s:available_nrules') ==# []
  end
end

describe 'smartinput#define_default_rules'
  before
    SaveContext
  end

  after
    ResetContext
  end

  it 'should define many rules'
    call smartinput#clear_rules()
    Expect Ref('s:available_nrules') ==# []

    call smartinput#define_default_rules()
    Expect Ref('s:available_nrules') !=# []
  end

  it 'should override existing rules if conflicted'
    call smartinput#clear_rules()
    Expect Ref('s:available_nrules') ==# []

    call smartinput#define_rule({'at': 'x\%#', 'char': '(', 'input': '---'})
    call smartinput#define_rule({'at': '\%#', 'char': '(', 'input': '---'})
    Expect len(Ref('s:available_nrules')) == 2

    let unconflicted_nrule = Ref('s:available_nrules')[0]
    let conflicted_nrule = Ref('s:available_nrules')[1]
    Expect unconflicted_nrule.at ==# 'x\%#'
    Expect conflicted_nrule.at ==# '\%#'

    call smartinput#define_default_rules()
    Expect Ref('s:available_nrules') !=# []
    Expect index(Ref('s:available_nrules'), unconflicted_nrule) != -1
    Expect index(Ref('s:available_nrules'), conflicted_nrule) == -1
  end

  " The behavior of each rules are tested
  " in 'The default configuration' block.
end

describe 'smartinput#define_rule'
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

    call smartinput#define_rule(b:uruleA)
    Expect Ref('s:available_nrules') ==# [b:nruleA]

    call smartinput#define_rule(b:uruleB)
    Expect Ref('s:available_nrules') ==# [b:nruleB, b:nruleA]
  end

  it 'should not define two or more "same" rules'
    " Because of the default configuration.
    Expect Ref('s:available_nrules') !=# []

    call Set('s:available_nrules', [])
    Expect Ref('s:available_nrules') ==# []

    call smartinput#define_rule(b:uruleA)
    Expect Ref('s:available_nrules') ==# [b:nruleA]

    call smartinput#define_rule(b:uruleA)
    Expect Ref('s:available_nrules') ==# [b:nruleA]

    call smartinput#define_rule(b:uruleB)
    Expect Ref('s:available_nrules') ==# [b:nruleB, b:nruleA]

    call smartinput#define_rule(b:uruleBd)
    Expect Ref('s:available_nrules') ==# [b:nruleBd, b:nruleA]
  end

  it 'should sort defined rules by priority in descending order (1)'
    Expect b:nruleA.priority < b:nruleB.priority

    " Because of the default configuration.
    Expect Ref('s:available_nrules') !=# []

    call Set('s:available_nrules', [])
    Expect Ref('s:available_nrules') ==# []

    call smartinput#define_rule(b:uruleA)
    call smartinput#define_rule(b:uruleB)
    Expect Ref('s:available_nrules') ==# [b:nruleB, b:nruleA]

  end

  it 'should sort defined rules by priority in descending order (2)'
    Expect b:nruleA.priority < b:nruleB.priority

    " Because of the default configuration.
    Expect Ref('s:available_nrules') !=# []

    call Set('s:available_nrules', [])
    Expect Ref('s:available_nrules') ==# []

    call smartinput#define_rule(b:uruleB)
    call smartinput#define_rule(b:uruleA)
    Expect Ref('s:available_nrules') ==# [b:nruleB, b:nruleA]
  end

  it 'should sort defined rules by "priority" and "at" in descending order (1)'
    Expect b:nruleC1.priority == b:nruleC2.priority
    Expect b:nruleC1.at <# b:nruleC2.at

    " Because of the default configuration.
    Expect Ref('s:available_nrules') !=# []

    call Set('s:available_nrules', [])
    Expect Ref('s:available_nrules') ==# []

    call smartinput#define_rule(b:uruleC1)
    call smartinput#define_rule(b:uruleC2)
    Expect Ref('s:available_nrules') ==# [b:nruleC2, b:nruleC1]
  end

  it 'should sort defined rules by "priority" and "at" in descending order (2)'
    Expect b:nruleC1.priority == b:nruleC2.priority
    Expect b:nruleC1.at <# b:nruleC2.at

    " Because of the default configuration.
    Expect Ref('s:available_nrules') !=# []

    call Set('s:available_nrules', [])
    Expect Ref('s:available_nrules') ==# []

    call smartinput#define_rule(b:uruleC2)
    call smartinput#define_rule(b:uruleC1)
    Expect Ref('s:available_nrules') ==# [b:nruleC2, b:nruleC1]
  end
end

describe 'smartinput#map_to_trigger'
  before
    SaveContext
    new

    let M = function('smartinput#map_to_trigger')

    " With a cursor adjustment.
    call smartinput#define_rule({
    \   'at': '\%#',
    \   'char': '(',
    \   'input': '()<Left>',
    \ })
    call M('i', '<buffer> (', '(', '(')

    " Without any cursor adjustment.
    call smartinput#define_rule({
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
    call smartinput#define_rule({
    \   'at': '(\%#)',
    \   'char': '<BS>',
    \   'input': '<BS><Del>',
    \ })
    call M('i', '<buffer> <BS>', '<BS>', '<BS>')

    " With a problematic "char" - ``"''.
    call smartinput#define_rule({
    \   'at': '\%#',
    \   'char': '"',
    \   'input': '""<Left>',
    \ })
    call M('i', '<buffer> "', '"', '"')

    " With a problematic "char" - ``\''.
    call smartinput#define_rule({
    \   'at': '\%#',
    \   'char': '<Bslash>',
    \   'input': '<Bslash><Bslash><Left>',
    \ })
    call M('i', '<buffer> <Bslash>', '<Bslash>', '<Bslash>')

    " With automatic indentation.
    call smartinput#define_rule({
    \   'at': '{\%#}',
    \   'char': '<Return>',
    \   'input': '<Return>*<Return>}<BS><Up><C-o>$<BS>',
    \ })
    call M('i', '<buffer> <Return>', '<Return>', '<Return>')

    " In Command-line mode.
    call smartinput#define_rule({
    \   'at': '\[\%#]',
    \   'char': '<BS>',
    \   'input': '<BS><Del>',
    \   'mode': ':',
    \ })
    call M('c', '<buffer> <BS>', '<BS>', '<BS>')
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

  it 'should do smart input assistant in Command-line mode'
    let b:log = []
    function! b:check()
      call add(b:log, [getcmdtype(), getcmdline(), getcmdpos()])
      return ''
    endfunction
    cnoremap <buffer> <expr> C  b:check()

    " '([x#])'
    " '([#])'
    " '(#)'
    " '#)'
    execute 'normal' ":([x])\<Left>\<Left>C\<BS>C\<BS>C\<BS>C\<C-c>"
    Expect b:log ==# [
    \   [':', '([x])', 4],
    \   [':', '([])', 3],
    \   [':', '()', 2],
    \   [':', ')', 1],
    \ ]
  end
end

describe 'The default configuration'
  before
    new
    setlocal autoindent

    function! b:.test_rules(test_set_table)
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
      for n in sort(keys(a:test_set_table))
        let test_set = a:test_set_table[n]
        % delete _
        let i = 0  " For debugging.
        for [input, lines, linenr, colnr] in test_set
          let i += 1
          execute 'normal' 'a'.input
          Expect [n, i, getline(1, line('$'))] ==# [n, i, lines]
          Expect [n, i, [line('.'), col('.')]] ==# [n, i, [linenr, colnr]]
        endfor
      endfor
    endfunction
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
    call b:.test_rules({
    \   '"" complete': [
    \     ["\"", ['""'], 1, 2 - 1],
    \   ],
    \   '"" escape #1': [
    \     ["\\", ['\'], 1, 2 - 1],
    \     ["\"", ['\"'], 1, 3 - 1],
    \   ],
    \   '"" escape #2': [
    \     ["\"", ['""'], 1, 2 - 1],
    \     ["\\", ['"\"'], 1, 3 - 1],
    \     ["\"", ['"\""'], 1, 4 - 1],
    \     ["\"", ['"\""'], 1, 5 - 1],
    \   ],
    \   '"" leave #1': [
    \     ["\"", ['""'], 1, 2 - 1],
    \     ["\"", ['""'], 1, 3 - 1],
    \   ],
    \   '"" leave #2': [
    \     ["\"", ['""'], 1, 2 - 1],
    \     ["x", ['"x"'], 1, 3 - 1],
    \     ["\"", ['"x"'], 1, 4 - 1],
    \   ],
    \   '"" undo #1': [
    \     ["\"", ['""'], 1, 2 - 1],
    \     ["x", ['"x"'], 1, 3 - 1],
    \     ["\<BS>", ['""'], 1, 2 - 1],
    \     ["\<BS>", [''], 1, 0 + 1],
    \   ],
    \   '"" undo #2': [
    \     ["x", ['x'], 1, 2 - 1],
    \     ["\"", ['x""'], 1, 3 - 1],
    \     ["\"", ['x""'], 1, 4 - 1],
    \     ["\<BS>", ['x'], 1, 2 - 1],
    \   ],
    \   '""" complete': [
    \     ["\"", ['""'], 1, 2 - 1],
    \     ["\"", ['""'], 1, 3 - 1],
    \     ["\"", ['""""""'], 1, 4 - 1],
    \   ],
    \   '""" leave #1': [
    \     ["\"", ['""'], 1, 2 - 1],
    \     ["\"", ['""'], 1, 3 - 1],
    \     ["\"", ['""""""'], 1, 4 - 1],
    \     ["\"", ['""""""'], 1, 7 - 1],
    \   ],
    \   '""" leave #2': [
    \     ["\"", ['""'], 1, 2 - 1],
    \     ["\"", ['""'], 1, 3 - 1],
    \     ["\"", ['""""""'], 1, 4 - 1],
    \     ["x", ['"""x"""'], 1, 5 - 1],
    \     ["\"", ['"""x"""'], 1, 8 - 1],
    \   ],
    \   '""" undo #1': [
    \     ["\"", ['""'], 1, 2 - 1],
    \     ["\"", ['""'], 1, 3 - 1],
    \     ["\"", ['""""""'], 1, 4 - 1],
    \     ["x", ['"""x"""'], 1, 5 - 1],
    \     ["\<BS>", ['""""""'], 1, 4 - 1],
    \     ["\<BS>", [''], 1, 0 + 1],
    \   ],
    \   '""" undo #2': [
    \     ["x", ['x'], 1, 2 - 1],
    \     ["\"", ['x""'], 1, 3 - 1],
    \     ["\"", ['x""'], 1, 4 - 1],
    \     ["\"", ['x""""""'], 1, 5 - 1],
    \     ["\<End>", ['x""""""'], 1, 8 - 1],
    \     ["\<BS>", ['x'], 1, 2 - 1],
    \   ],
    \   '''''': [
    \     ["'", [''''''], 1, 2 - 1],
    \     ["'", [''''''], 1, 3 - 1],
    \     ["\<Left>", [''''''], 1, 2 - 1],
    \     ["x", ['''x'''], 1, 3 - 1],
    \     ["'", ['''x'''], 1, 4 - 1],
    \     ["\<Left>", ['''x'''], 1, 3 - 1],
    \     ["\<BS>", [''''''], 1, 2 - 1],
    \     ["\<BS>", [''], 1, 2 - 1],
    \     ["\\", ['\'], 1, 2 - 1],
    \     ["'", ['\'''], 1, 3 - 1],
    \   ],
    \   ''''' complete': [
    \     ["'", [''''''], 1, 2 - 1],
    \   ],
    \   ''''' escape #1': [
    \     ["\\", ['\'], 1, 2 - 1],
    \     ["'", ['\'''], 1, 3 - 1],
    \   ],
    \   ''''' escape #2': [
    \     ["'", [''''''], 1, 2 - 1],
    \     ["\\", ['''\'''], 1, 3 - 1],
    \     ["'", ['''\'''''], 1, 4 - 1],
    \     ["'", ['''\'''''], 1, 5 - 1],
    \   ],
    \   ''''' leave #1': [
    \     ["'", [''''''], 1, 2 - 1],
    \     ["'", [''''''], 1, 3 - 1],
    \   ],
    \   ''''' leave #2': [
    \     ["'", [''''''], 1, 2 - 1],
    \     ["x", ['''x'''], 1, 3 - 1],
    \     ["'", ['''x'''], 1, 4 - 1],
    \   ],
    \   ''''' undo #1': [
    \     ["'", [''''''], 1, 2 - 1],
    \     ["x", ['''x'''], 1, 3 - 1],
    \     ["\<BS>", [''''''], 1, 2 - 1],
    \     ["\<BS>", [''], 1, 0 + 1],
    \   ],
    \   ''''' undo #2': [
    \     ["x", ['x'], 1, 2 - 1],
    \     ["\<C-v>'", ['x'''], 1, 3 - 1],
    \     ["\<C-v>'", ['x'''''], 1, 4 - 1],
    \     ["\<BS>", ['x'], 1, 2 - 1],
    \   ],
    \   ''''''' complete': [
    \     ["'", [''''''], 1, 2 - 1],
    \     ["'", [''''''], 1, 3 - 1],
    \     ["'", [''''''''''''''], 1, 4 - 1],
    \   ],
    \   ''''''' leave #1': [
    \     ["'", [''''''], 1, 2 - 1],
    \     ["'", [''''''], 1, 3 - 1],
    \     ["'", [''''''''''''''], 1, 4 - 1],
    \     ["'", [''''''''''''''], 1, 7 - 1],
    \   ],
    \   ''''''' leave #2': [
    \     ["'", [''''''], 1, 2 - 1],
    \     ["'", [''''''], 1, 3 - 1],
    \     ["'", [''''''''''''''], 1, 4 - 1],
    \     ["x", ['''''''x'''''''], 1, 5 - 1],
    \     ["'", ['''''''x'''''''], 1, 8 - 1],
    \   ],
    \   ''''''' undo #1': [
    \     ["'", [''''''], 1, 2 - 1],
    \     ["'", [''''''], 1, 3 - 1],
    \     ["'", [''''''''''''''], 1, 4 - 1],
    \     ["x", ['''''''x'''''''], 1, 5 - 1],
    \     ["\<BS>", [''''''''''''''], 1, 4 - 1],
    \     ["\<BS>", [''], 1, 0 + 1],
    \   ],
    \   ''''''' undo #2': [
    \     ["x", ['x'], 1, 2 - 1],
    \     ["\<C-v>'", ['x'''], 1, 3 - 1],
    \     ["\<C-v>'", ['x'''''], 1, 4 - 1],
    \     ["'", ['x'''''''''''''], 1, 5 - 1],
    \     ["\<End>", ['x'''''''''''''], 1, 8 - 1],
    \     ["\<BS>", ['x'], 1, 2 - 1],
    \   ],
    \   '() complete': [
    \     ["(", ['()'], 1, 2 - 1],
    \   ],
    \   '() escape': [
    \     ["\\", ['\'], 1, 2 - 1],
    \     ["(", ['\('], 1, 3 - 1],
    \   ],
    \   '() leave #1': [
    \     ["(", ['()'], 1, 2 - 1],
    \     [")", ['()'], 1, 3 - 1],
    \   ],
    \   '() leave #2': [
    \     ["(", ['()'], 1, 2 - 1],
    \     ["x", ['(x)'], 1, 3 - 1],
    \     [")", ['(x)'], 1, 4 - 1],
    \   ],
    \   '() leave #3': [
    \     ["(", ['()'], 1, 2 - 1],
    \     ["  x  \<Left>\<Left>", ['(  x  )'], 1, 5 - 1],
    \     [")", ['(  x  )'], 1, 8 - 1],
    \   ],
    \   '() leave #4': [
    \     ["(", ['()'], 1, 2 - 1],
    \     ["\<Enter>x", ['(', 'x', ')'], 2, 2 - 1],
    \     [")", ['(', 'x', ')'], 3, 2 - 1],
    \   ],
    \   '() leave #5': [
    \     ["(", ['()'], 1, 2 - 1],
    \     ["\<Enter>", ['(', '', ')'], 2, 0 + 1],
    \     ["(", ['(', '()', ')'], 2, 2 - 1],
    \     ["\<Enter>x", ['(', '(', 'x', ')', ')'], 3, 2 - 1],
    \     [")", ['(', '(', 'x', ')', ')'], 4, 2 - 1],
    \     [")", ['(', '(', 'x', ')', ')'], 5, 2 - 1],
    \   ],
    \   '() undo #1': [
    \     ["(", ['()'], 1, 2 - 1],
    \     ["x", ['(x)'], 1, 3 - 1],
    \     ["\<BS>", ['()'], 1, 2 - 1],
    \     ["\<BS>", [''], 1, 0 + 1],
    \   ],
    \   '() undo #2': [
    \     ["x", ['x'], 1, 2 - 1],
    \     ["(", ['x()'], 1, 3 - 1],
    \     [")", ['x()'], 1, 4 - 1],
    \     ["\<BS>", ['x'], 1, 2 - 1],
    \   ],
    \   'English': [
    \     ["Let", ['Let'], 1, 4 - 1],
    \     ["'", ['Let'''], 1, 5 - 1],
    \     ["s", ['Let''s'], 1, 6 - 1],
    \     [" ", ['Let''s '], 1, 7 - 1],
    \     ["'", ['Let''s '''''], 1, 8 - 1],
    \     ["quote", ['Let''s ''quote'''], 1, 13 - 1],
    \   ],
    \   '[] complete': [
    \     ["[", ['[]'], 1, 2 - 1],
    \   ],
    \   '[] escape': [
    \     ["\\", ['\'], 1, 2 - 1],
    \     ["[", ['\['], 1, 3 - 1],
    \   ],
    \   '[] leave #1': [
    \     ["[", ['[]'], 1, 2 - 1],
    \     ["]", ['[]'], 1, 3 - 1],
    \   ],
    \   '[] leave #2': [
    \     ["[", ['[]'], 1, 2 - 1],
    \     ["x", ['[x]'], 1, 3 - 1],
    \     ["]", ['[x]'], 1, 4 - 1],
    \   ],
    \   '[] leave #3': [
    \     ["[", ['[]'], 1, 2 - 1],
    \     ["  x  \<Left>\<Left>", ['[  x  ]'], 1, 5 - 1],
    \     ["]", ['[  x  ]'], 1, 8 - 1],
    \   ],
    \   '[] leave #4': [
    \     ["[", ['[]'], 1, 2 - 1],
    \     ["\<Enter>x\<Enter>\<Up>\<Right>", ['[', 'x', ']'], 2, 2 - 1],
    \     ["]", ['[', 'x', ']'], 3, 2 - 1],
    \   ],
    \   '[] leave #5': [
    \     ["[", ['[]'], 1, 2 - 1],
    \     ["\<Enter>\<Enter>\<Up>", ['[', '', ']'], 2, 0 + 1],
    \     ["[", ['[', '[]', ']'], 2, 2 - 1],
    \     ["\<Enter>\<Enter>\<Up>x", ['[', '[', 'x', ']', ']'], 3, 2 - 1],
    \     ["]", ['[', '[', 'x', ']', ']'], 4, 2 - 1],
    \     ["]", ['[', '[', 'x', ']', ']'], 5, 2 - 1],
    \   ],
    \   '[] undo #1': [
    \     ["[", ['[]'], 1, 2 - 1],
    \     ["x", ['[x]'], 1, 3 - 1],
    \     ["\<BS>", ['[]'], 1, 2 - 1],
    \     ["\<BS>", [''], 1, 0 + 1],
    \   ],
    \   '[] undo #2': [
    \     ["x", ['x'], 1, 2 - 1],
    \     ["[", ['x[]'], 1, 3 - 1],
    \     ["]", ['x[]'], 1, 4 - 1],
    \     ["\<BS>", ['x'], 1, 2 - 1],
    \   ],
    \   '`` complete': [
    \     ["`", ['``'], 1, 2 - 1],
    \   ],
    \   '`` escape #1': [
    \     ["\\", ['\'], 1, 2 - 1],
    \     ["`", ['\`'], 1, 3 - 1],
    \   ],
    \   '`` escape #2': [
    \     ["`", ['``'], 1, 2 - 1],
    \     ["\\", ['`\`'], 1, 3 - 1],
    \     ["`", ['`\``'], 1, 4 - 1],
    \     ["`", ['`\``'], 1, 5 - 1],
    \   ],
    \   '`` leave #1': [
    \     ["`", ['``'], 1, 2 - 1],
    \     ["`", ['``'], 1, 3 - 1],
    \   ],
    \   '`` leave #2': [
    \     ["`", ['``'], 1, 2 - 1],
    \     ["x", ['`x`'], 1, 3 - 1],
    \     ["`", ['`x`'], 1, 4 - 1],
    \   ],
    \   '`` undo #1': [
    \     ["`", ['``'], 1, 2 - 1],
    \     ["x", ['`x`'], 1, 3 - 1],
    \     ["\<BS>", ['``'], 1, 2 - 1],
    \     ["\<BS>", [''], 1, 0 + 1],
    \   ],
    \   '`` undo #2': [
    \     ["x", ['x'], 1, 2 - 1],
    \     ["`", ['x``'], 1, 3 - 1],
    \     ["`", ['x``'], 1, 4 - 1],
    \     ["\<BS>", ['x'], 1, 2 - 1],
    \   ],
    \   '``` complete': [
    \     ["`", ['``'], 1, 2 - 1],
    \     ["`", ['``'], 1, 3 - 1],
    \     ["`", ['``````'], 1, 4 - 1],
    \   ],
    \   '``` leave #1': [
    \     ["`", ['``'], 1, 2 - 1],
    \     ["`", ['``'], 1, 3 - 1],
    \     ["`", ['``````'], 1, 4 - 1],
    \     ["`", ['``````'], 1, 7 - 1],
    \   ],
    \   '``` leave #2': [
    \     ["`", ['``'], 1, 2 - 1],
    \     ["`", ['``'], 1, 3 - 1],
    \     ["`", ['``````'], 1, 4 - 1],
    \     ["x", ['```x```'], 1, 5 - 1],
    \     ["`", ['```x```'], 1, 8 - 1],
    \   ],
    \   '``` undo #1': [
    \     ["`", ['``'], 1, 2 - 1],
    \     ["`", ['``'], 1, 3 - 1],
    \     ["`", ['``````'], 1, 4 - 1],
    \     ["x", ['```x```'], 1, 5 - 1],
    \     ["\<BS>", ['``````'], 1, 4 - 1],
    \     ["\<BS>", [''], 1, 0 + 1],
    \   ],
    \   '``` undo #2': [
    \     ["x", ['x'], 1, 2 - 1],
    \     ["`", ['x``'], 1, 3 - 1],
    \     ["`", ['x``'], 1, 4 - 1],
    \     ["`", ['x``````'], 1, 5 - 1],
    \     ["\<End>", ['x``````'], 1, 8 - 1],
    \     ["\<BS>", ['x'], 1, 2 - 1],
    \   ],
    \   '{} complete': [
    \     ["{", ['{}'], 1, 2 - 1],
    \   ],
    \   '{} escape': [
    \     ["\\", ['\'], 1, 2 - 1],
    \     ["{", ['\{'], 1, 3 - 1],
    \   ],
    \   '{} leave #1': [
    \     ["{", ['{}'], 1, 2 - 1],
    \     ["}", ['{}'], 1, 3 - 1],
    \   ],
    \   '{} leave #2': [
    \     ["{", ['{}'], 1, 2 - 1],
    \     ["x", ['{x}'], 1, 3 - 1],
    \     ["}", ['{x}'], 1, 4 - 1],
    \   ],
    \   '{} leave #3': [
    \     ["{", ['{}'], 1, 2 - 1],
    \     ["  x  \<Left>\<Left>", ['{  x  }'], 1, 5 - 1],
    \     ["}", ['{  x  }'], 1, 8 - 1],
    \   ],
    \   '{} leave #4': [
    \     ["{", ['{}'], 1, 2 - 1],
    \     ["\<Enter>  x", ['{', '  x', '}'], 2, 4 - 1],
    \     ["}", ['{', '  x', '}'], 3, 2 - 1],
    \   ],
    \   '{} leave #5': [
    \     ["{", ['{}'], 1, 2 - 1],
    \     ["\<Enter>  ", ['{', '  ', '}'], 2, 3 - 1],
    \     ["{", ['{', '  {}', '}'], 2, 4 - 1],
    \     ["\<Enter>  x", ['{', '  {', '    x', '  }', '}'], 3, 6 - 1],
    \     ["}", ['{', '  {', '    x', '  }', '}'], 4, 4 - 1],
    \     ["}", ['{', '  {', '    x', '  }', '}'], 5, 2 - 1],
    \   ],
    \   '{} undo #1': [
    \     ["{", ['{}'], 1, 2 - 1],
    \     ["x", ['{x}'], 1, 3 - 1],
    \     ["\<BS>", ['{}'], 1, 2 - 1],
    \     ["\<BS>", [''], 1, 0 + 1],
    \   ],
    \   '{} undo #2': [
    \     ["x", ['x'], 1, 2 - 1],
    \     ["{", ['x{}'], 1, 3 - 1],
    \     ["}", ['x{}'], 1, 4 - 1],
    \     ["\<BS>", ['x'], 1, 2 - 1],
    \   ],
    \ })
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

    setlocal filetype=clojure
    setlocal syntax=lisp
    Expect &l:filetype ==# 'clojure'
    Expect &l:syntax ==# 'lisp'
    normal S(def filetype 'clojure
    Expect getline(1, line('$')) ==# ['(def filetype ''clojure)']
    Expect [line('.'), col('.')] ==# [1, 23 - 1]
    Expect b:getSynNames(line('.'), col('.')) ==# ['lispList', 'Identifier']
    normal S(def filetype "'clojure
    Expect getline(1, line('$')) ==# ['(def filetype "''clojure''")']
    Expect [line('.'), col('.')] ==# [1, 24 - 1]
    Expect b:getSynNames(line('.'), col('.')) ==# ['lispList', 'Constant']
    normal S; (def filetype 'clojure
    Expect getline(1, line('$')) ==# ['; (def filetype ''clojure)']
    Expect [line('.'), col('.')] ==# [1, 25 - 1]
    Expect b:getSynNames(line('.'), col('.')) ==# ['Comment']
  end

  it 'should have rules to expand a () block and a {} block'
    setfiletype ruby
    setlocal expandtab shiftwidth=2 softtabstop=2

    let keys = ["\<Enter>", "\<Return>", "\<CR>", "\<C-m>", "\<NL>", "\<C-j>"]
    for additional_indentkeys in ['', '*<Return>']
      " Some configurations for automatic indentation perform indentation
      " before breaking the current line, while the others do not so.  For
      " example, $VIMRUNTIME/indent/php.vim performs such indentation.  So
      " that we have to test both cases.
      setlocal indentkeys<
      let &l:indentkeys .= ',' . additional_indentkeys

      for key in keys
        let note = [strtrans(key), additional_indentkeys]

        % delete _
        execute 'normal' printf('ifoo(%sbar,%sbaz', key, key)
        Expect [note, line('.'), col('.'), getline(1, line('$'))]
        \ ==# [
        \   note,
        \   3, 6 - 1,
        \   [
        \     'foo(',
        \     '  bar,',
        \     '  baz',
        \     ')',
        \   ],
        \ ]

        % delete _
        execute 'normal' printf('i{%sfoo()%sbar()', key, key)
        Expect [note, line('.'), col('.'), getline(1, line('$'))]
        \ ==# [
        \   note,
        \   3, 8 - 1,
        \   [
        \     '{',
        \     '  foo()',
        \     '  bar()',
        \     '}',
        \   ],
        \ ]
      endfor
    endfor
  end

  it 'should have rules to input comments and strings easily in Vim script'
    setfiletype vim

    " `"` at the beginning of a line must be a comment sign.
    % delete _
    execute 'normal' 'i" This is a comment.'
    Expect getline(1, line('$')) ==# ['" This is a comment.']
    Expect [line('.'), col('.')] ==# [1, 21 - 1]

    " The comment sign may be indented.
    % delete _
    execute 'normal' 'i  " This is an indented comment.'
    Expect getline(1, line('$')) ==# ['  " This is an indented comment.']
    Expect [line('.'), col('.')] ==# [1, 33 - 1]

    " In a comment, `"` is usually inserted as a string literal or an ordinary
    " English word.  So that it should be completed.
    % delete _
    execute 'normal' 'i" This is a '
    execute 'normal' 'a"'
    execute 'normal' 'acomment'
    Expect getline(1, line('$')) ==# ['" This is a "comment"']
    Expect [line('.'), col('.')] ==# [1, 21 - 1]

    " `"` after an operator is usually a string literal.
    % delete _
    execute 'normal' 'ilet foo = bar . "baz'
    Expect getline(1, line('$')) ==# ['let foo = bar . "baz"']
    Expect [line('.'), col('.')] ==# [1, 21 - 1]

    " But it's hard to guess all cases.  We assume only `"` at the beginning
    " of a line is a comment sign.  In other words, `"` after non-indent
    " character is always treated as a string literal.
    % delete _
    execute 'normal' 'ilet foo = bar " baz'
    Expect getline(1, line('$')) ==# ['let foo = bar " baz"']
    Expect [line('.'), col('.')] ==# [1, 20 - 1]
  end

  it 'should have rules for "strong quote" in specific languages'
    for [is_strong, filetype] in [
    \   [0, 'c'],
    \   [0, 'cpp'],
    \   [0, 'cs'],
    \   [0, 'javascript'],
    \   [0, 'python'],
    \   [1, 'csh'],
    \   [1, 'perl'],
    \   [1, 'ruby'],
    \   [1, 'sh'],
    \   [1, 'tcsh'],
    \   [1, 'vim'],
    \   [1, 'zsh'],
    \ ]
      let &l:filetype = filetype
      % delete _
      let test_cases = [
      \   ["'", [[''''''], [1, 2 - 1]], [[''''''], [1, 2 - 1]]],
      \   ["\\", [['''\'''], [1, 3 - 1]], [['''\'''], [1, 3 - 1]]],
      \   ["'", [['''\'''''], [1, 4 - 1]], [['''\'''], [1, 4 - 1]]],
      \   ["'", [['''\'''''], [1, 5 - 1]], [['''\'''''''], [1, 5 - 1]]],
      \ ]
      for i in range(len(test_cases))
        let [input, expected_weak, expected_strong] = test_cases[i]
        let expected = is_strong ? expected_strong : expected_weak
        execute 'normal' 'a'.input
        Expect [&l:filetype, i, [getline(1, line('$')), [line('.'), col('.')]]]
        \ ==# [filetype, i, expected]
      endfor
    endfor
  end

  it 'should have rules for Python-specific string literals'
    setfiletype python

    let test_set_table = {}
    for prefix in ['r', 'R',
    \              'b', 'B', 'br', 'bR', 'Br', 'BR',
    \              'u', 'U', 'ur', 'uR', 'Ur', 'UR']
      let test_set_table[printf('%s''...'' in code', prefix)] = [
      \   [prefix . "", [prefix . ''], 1, len(prefix) + 1 - 1],
      \   ["'", [prefix . ''''''], 1, len(prefix) + 2 - 1],
      \   ["x", [prefix . '''x'''], 1, len(prefix) + 3 - 1],
      \ ]
      let test_set_table[printf('%s''...'' in string', prefix)] = [
      \   ["\"", ['""'], 1, 1 + 1 - 1],
      \   [prefix . "", ['"' . prefix . '"'], 1, 1 + len(prefix) + 1 - 1],
      \   ["'", ['"' . prefix . '''"'], 1, 1 + len(prefix) + 1 + 1 - 1],
      \   ["x", ['"' . prefix . '''x"'], 1, 1 + len(prefix) + 2 + 1 - 1],
      \ ]
      let test_set_table[printf('%s''...'' in comment (middle)', prefix)] = [
      \   ["# $\<Left>", ['# $'], 1, 2 + 1 - 1],
      \   [prefix . "", ['# ' . prefix . '$'], 1, 2 + len(prefix) + 1 - 1],
      \   ["'", ['# ' . prefix . '''$'], 1, 2 + len(prefix) + 1 + 1 - 1],
      \   ["x", ['# ' . prefix . '''x$'], 1, 2 + len(prefix) + 2 + 1 - 1],
      \ ]
      let test_set_table[printf('%s''...'' in comment (EOL)', prefix)] = [
      \   ["foo # ", ['foo # '], 1, 6 + 1 - 1],
      \   [prefix . "", ['foo # ' . prefix . ''], 1, 6 + len(prefix) + 1 - 1],
      \   ["'", ['foo # ' . prefix . ''''], 1, 6 + len(prefix) + 1 + 1 - 1],
      \   ["x", ['foo # ' . prefix . '''x'], 1, 6 + len(prefix) + 2 + 1 - 1],
      \ ]
    endfor
    let test_set_table['Typical comment'] = [
    \   ["# You", ['# You'], 1, 6 - 1],
    \   ["'", ['# You'''], 1, 7 - 1],
    \   ["re", ['# You''re'], 1, 9 - 1],
    \ ]

    call b:.test_rules(test_set_table)
  end

  it 'should be cooperative with Visual-block Insert'
    for input in ['(foo)bar:', '[foo]bar', '{foo}bar:']
      % delete _
      put =['a', 'b', 'c', 'd']
      1 delete _
      execute 'normal' "gg0\<C-v>GI".input."\<Esc>"
      Expect getline(1, '$') ==# [
      \   input . 'a',
      \   input . 'b',
      \   input . 'c',
      \   input . 'd',
      \ ]
      Expect [line('.'), col('.')] ==# [1, 0 + 1]
    endfor
  end

  it 'should be escaped immediately after expanding a block'
    " Insert mode will never be nested if keys are typed interactively.  But
    " some key sequences (such as i<C-o>S) typed via :normal or :map cause
    " "nested" Insert mode, so that <Esc> must be typed twice to return to
    " Normal mode.  We have to avoid using such key sequences at the moment.
    " See also: http://groups.google.com/group/vim_dev/browse_thread/thread/a1948a72bb919900

    % delete _
    execute 'normal' "ifoo\<Esc>I{\<Return>\<Esc>/o\<Return>"
    Expect getline(1, '$') ==# [
    \   '{',
    \   '',
    \   '}foo',
    \ ]
    " or ['{', '/o', '', '}foo'] if Insert mode is nested.
    Expect [line('.'), col('.')] ==# [3, 3]

    % delete _
    execute 'normal' "ifoo\<Esc>I(\<Return>\<Esc>/o\<Return>"
    Expect getline(1, '$') ==# [
    \   '(',
    \   '',
    \   ')foo',
    \ ]
    " or ['(', '/o', '', ')foo'] if Insert mode is nested.
    Expect [line('.'), col('.')] ==# [3, 3]
  end

  it 'should keep register contents'
    % delete _
    let @" = 'foo'
    execute 'normal' "i{\<Return>"
    Expect getline(1, '$') ==# [
    \   '{',
    \   '',
    \   '}',
    \ ]
    Expect [line('.'), col('.')] ==# [2, 0 + 1]
    Expect @" ==# 'foo'
    Expect @0 ==# 'foo'

    % delete _
    let @" = 'foo'
    execute 'normal' "i(\<Return>"
    Expect getline(1, '$') ==# [
    \   '(',
    \   '',
    \   ')',
    \ ]
    Expect [line('.'), col('.')] ==# [2, 0 + 1]
    Expect @" ==# 'foo'
    Expect @0 ==# 'foo'
  end
end
