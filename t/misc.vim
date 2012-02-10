call vspec#hint({'scope': 'smartpunc#scope()', 'sid': 'smartpunc#sid()'})

describe 's:are_same_rules'
  before
    new
    let b:nruleA = Call('s:normalize_rule', {
    \   'at': '\%#',
    \   'char': '(',
    \   'input': '()<Left>',
    \ })
    let b:nruleAd = Call('s:normalize_rule', {
    \   'at': '\%#',
    \   'char': '(',
    \   'input': '(  )<Left><Left>',
    \ })
    let b:nruleB = Call('s:normalize_rule', {
    \   'at': '\%#',
    \   'char': '[',
    \   'input': '[]<Left>',
    \   'filetype': ['lisp', 'scheme'],
    \ })
    let b:nruleBd = Call('s:normalize_rule', {
    \   'at': '\%#',
    \   'char': '[',
    \   'input': '[  ]<Left><Left>',
    \   'filetype': ['scheme', 'lisp'],
    \ })
    let b:nruleC = Call('s:normalize_rule', {
    \   'at': '\%#',
    \   'char': '[',
    \   'input': '[]<Left>',
    \ })
  end

  after
    close!
  end

  it 'should return true for rules with the same values'
    Expect Call('s:are_same_rules', b:nruleA, b:nruleA) toBeTrue
    Expect Call('s:are_same_rules', b:nruleAd, b:nruleAd) toBeTrue
    Expect Call('s:are_same_rules', b:nruleBd, b:nruleBd) toBeTrue
    Expect Call('s:are_same_rules', b:nruleB, b:nruleB) toBeTrue
    Expect Call('s:are_same_rules', b:nruleC, b:nruleC) toBeTrue
  end

  it 'should return false for rules with different values'
    Expect Call('s:are_same_rules', b:nruleA, b:nruleB) toBeFalse
    Expect Call('s:are_same_rules', b:nruleAd, b:nruleBd) toBeFalse
    Expect Call('s:are_same_rules', b:nruleB, b:nruleC) toBeFalse
  end

  it 'should compare all items but "input" in rules'
    Expect Call('s:are_same_rules', b:nruleA, b:nruleAd) toBeTrue
    Expect Call('s:are_same_rules', b:nruleB, b:nruleBd) toBeTrue
  end
end

describe 's:calculate_rule_priority'
  it 'should use "at", "filetype" and "syntax"'
    let snrule1 = {
    \   'at': '\%#',
    \   'char': '(',
    \   'input': '()<Left>',
    \   'filetype': ['foo', 'bar', 'baz'],
    \   'syntax': ['String', 'Comment'],
    \ }
    Expect Call('s:calculate_rule_priority', snrule1) == 3 + 100 / 3 + 100 / 2

    let snrule2 = {
    \   'at': '\%#',
    \   'char': '[',
    \   'input': '[  ]<Left><Left>',
    \   'filetype': ['foo', 'bar', 'baz'],
    \   'syntax': ['String', 'Comment'],
    \ }
    Expect Call('s:calculate_rule_priority', snrule2) == 3 + 100 / 3 + 100 / 2
  end

  it 'should use a low value for omitted items'
    let snrule = {
    \   'at': '\%#',
    \   'char': '(',
    \   'input': '()<Left>',
    \   'filetype': 0,
    \   'syntax': 0,
    \ }
    Expect Call('s:calculate_rule_priority', snrule) == 3 + 0 + 0
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
    \   'filetype': 0,
    \   'syntax': 0,
    \   'priority': 3 + 0 + 0,
    \ }
  end
end

describe 's:remove_a_same_rule'
  it 'should remove a same rule by equivalence and in place'
    let _nruleA = {
    \   'at': '\%#',
    \   'char': '(',
    \   'input': '()<Left>',
    \ }
    let nruleA = Call('s:normalize_rule', _nruleA)
    let _nruleB = {
    \   'at': '\%#',
    \   'char': '[',
    \   'input': '[]<Left>',
    \ }
    let nruleB = Call('s:normalize_rule', _nruleB)
    let nrules = [nruleA, nruleB, nruleA, nruleA]

    call Call('s:remove_a_same_rule', nrules, deepcopy(nruleA))
    Expect nrules ==# [nruleB, nruleA, nruleA]
  end
end
