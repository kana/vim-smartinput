call vspec#hint({'scope': 'smartpunc#scope()', 'sid': 'smartpunc#sid()'})

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
