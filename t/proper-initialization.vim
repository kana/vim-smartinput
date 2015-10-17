describe 'the initialization steps'
  it 'should define the default rules fisrt, then user-defined rules'
    " Emulate stuffs in user's vimrc.
    call panacea#define_rule({'at': '\%#', 'char': '(', 'input': 'BAR'})
    call panacea#define_rule({'at': '', 'char': 'x', 'input': 'FOO'})
    call vspec#hint({'scope': 'panacea#scope()', 'sid': 'panacea#sid()'})

    " Emulate loading plugins.
    runtime! plugin/panacea.vim

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
    call panacea#map_trigger_keys()
    Expect maparg('x', 'i') !=# ''
  end
end
