" NB: MacVim defines several key mappings such as <D-v> by default.
" The key mappings are defined from the core, not from any runtime file.
" So that the key mappings are always defined even if Vim is invoked by
" "vim -u NONE" etc.  Remove the kay mappings to ensure that there is no key
" mappings, because some tests in this file assume such state.
imapclear

call vspec#hint({'scope': 'smartpunc#scope()', 'sid': 'smartpunc#sid()'})
set backspace=indent,eol,start

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
end

describe 'smartpunc#map_to_trigger'
  before
    SaveContext
    new

    " With a cursor adjustment.
    call smartpunc#define_rule({
    \   'at': '\%#',
    \   'char': '(',
    \   'input': '()<Left>',
    \ })
    call smartpunc#map_to_trigger('<buffer> (', '(', '(')

    " Without any cursor adjustment.
    call smartpunc#define_rule({
    \   'at': '\%#',
    \   'char': '1',
    \   'input': '123',
    \ })
    call smartpunc#map_to_trigger('<buffer> 1', '1', '1')

    " Failure case - 1.
    " ... no rule is defined for 'x' for intentional failure.
    call smartpunc#map_to_trigger('<buffer> F1', 'x', 'x')

    " Failure case - 2.
    " ... no rule is defined for 'y' for intentional failure.
    call smartpunc#map_to_trigger('<buffer> F2', 'x', 'y')

    " With a special "char".
    call smartpunc#define_rule({
    \   'at': '(\%#)',
    \   'char': '<BS>',
    \   'input': '<BS><Del>',
    \ })
    call smartpunc#map_to_trigger('<buffer> <BS>', '<BS>', '<BS>')

    " With a problematic "char" - ``"''.
    call smartpunc#define_rule({
    \   'at': '\%#',
    \   'char': '"',
    \   'input': '""<Left>',
    \ })
    call smartpunc#map_to_trigger('<buffer> "', '"', '"')

    " With a problematic "char" - ``\''.
    call smartpunc#define_rule({
    \   'at': '\%#',
    \   'char': '<Bslash>',
    \   'input': '<Bslash><Bslash><Left>',
    \ })
    call smartpunc#map_to_trigger('<buffer> <Bslash>', '<Bslash>', '<Bslash>')

    " With automatic indentation.
    call smartpunc#define_rule({
    \   'at': '{\%#}',
    \   'char': '<Return>',
    \   'input': '<Return>*<Return>}<BS><Up><C-o>$<BS>',
    \ })
    call smartpunc#map_to_trigger('<buffer> <Return>', '<Return>', '<Return>')
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
    \   '<',
    \   '<BS>',
    \   '<CR>',
    \   '>',
    \   '[',
    \   ']',
    \   '`',
    \   '{',
    \   '}',
    \ ]
  end

  it 'should have rules to complete corresponding characters'
    TODO
    " Write tests for each rules.
  end

  it 'should have rules to leave the current block easily'
    TODO
    " Write tests for each rules.
  end

  it 'should have rules to undo the completion easily'
    TODO
    " Write tests for each rules.
  end

  it 'should have rules to input metacharacter in strings/regexp'
    TODO
    " Write tests for each rules.
  end

  it 'should have rules to input English words'
    TODO
    " Write tests for each rules.
  end

  it 'should have rules to write Lisp/Scheme source code'
    TODO
    " Write tests for each rules.
  end

  it 'should have rules to write C-like syntax source code'
    TODO
    " Write tests for each rules.
  end
end
