describe 'the initialization steps'
  it 'should define the default rules fisrt, then user-defined rules'
    " Emulate stuffs in user's vimrc.
    call smartpunc#define_rule({'at': '\%#', 'char': '(', 'input': 'BAR'})
    call smartpunc#define_rule({'at': '', 'char': 'x', 'input': 'FOO'})
    call vspec#hint({'scope': 'smartpunc#scope()', 'sid': 'smartpunc#sid()'})

    " Emulate loading plugins.
    runtime! plugin/smartpunc.vim

    Expect Ref('s:loaded_count') == 1

    let nrules = Ref('s:available_nrules')
    let default_nrules = filter(copy(nrules), 'v:val.char !=# "x"')
    let user_original_nrules = filter(copy(nrules), 'v:val.char ==# "x"')
    let overridden_nrules = filter(copy(nrules),
    \                              'v:val.char ==# "(" && v:val.at ==# "\\%#"')
    Expect len(default_nrules) > 0
    Expect len(user_original_nrules) == 1
    Expect user_original_nrules[0].input ==# 'FOO'
    Expect len(overridden_nrules) == 1
    Expect overridden_nrules[0].input ==# 'BAR'

    Expect maparg('x', 'i') ==# ''
    call smartpunc#map_trigger_keys()
    Expect maparg('x', 'i') !=# ''
  end
end
