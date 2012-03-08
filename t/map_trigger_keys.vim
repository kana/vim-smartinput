let g:smartinput_no_default_key_mappings = !0

runtime! plugin/smartinput.vim

call vspec#hint({'scope': 'smartinput#scope()', 'sid': 'smartinput#sid()'})

describe 'smartinput#map_trigger_keys'
  before
    new

    function! b:get_lhss(map_command)
      redir => s
      execute '0 verbose' a:map_command
      redir END
      let lhss = split(s, '\n')
      call map(lhss, 'substitute(v:val, ''\v\S+\s+(\S+)\s+.*'', ''\1'', "g")')
      call sort(lhss)
      return lhss
    endfunction

    imapclear
    cmapclear
    call smartinput#clear_rules()
  end

  after
    close!
  end

  it 'should not map anything but "alias" ones if there is no rule'
    call smartinput#map_trigger_keys()

    Expect b:get_lhss('imap') ==# [
    \   '<C-H>',
    \   '<CR>',
    \   '<NL>',
    \ ]
    Expect b:get_lhss('cmap') ==# [
    \   '<C-H>',
    \   '<CR>',
    \   '<NL>',
    \ ]
  end

  it 'should not override existing key mappings if overridep is omitted'
    inoremap x  FOO
    call smartinput#define_rule({'at': '', 'char': 'x', 'input': 'BAR',
    \                          'mode': 'i'})
    cnoremap y  foo
    call smartinput#define_rule({'at': '', 'char': 'y', 'input': 'bar',
    \                          'mode': ':'})
    call smartinput#map_trigger_keys()

    Expect b:get_lhss('imap') ==# [
    \   '<C-H>',
    \   '<CR>',
    \   '<NL>',
    \   'x',
    \ ]
    Expect maparg('x', 'i') ==# 'FOO'
    Expect b:get_lhss('cmap') ==# [
    \   '<C-H>',
    \   '<CR>',
    \   '<NL>',
    \   'y',
    \ ]
    Expect maparg('y', 'c') ==# 'foo'
  end

  it 'should not override existing key mappings if overridep is false'
    inoremap x  FOO
    call smartinput#define_rule({'at': '', 'char': 'x', 'input': 'BAR',
    \                          'mode': 'i'})
    cnoremap y  foo
    call smartinput#define_rule({'at': '', 'char': 'y', 'input': 'bar',
    \                          'mode': ':'})
    call smartinput#map_trigger_keys(!!0)

    Expect b:get_lhss('imap') ==# [
    \   '<C-H>',
    \   '<CR>',
    \   '<NL>',
    \   'x',
    \ ]
    Expect maparg('x', 'i') ==# 'FOO'
    Expect b:get_lhss('cmap') ==# [
    \   '<C-H>',
    \   '<CR>',
    \   '<NL>',
    \   'y',
    \ ]
    Expect maparg('y', 'c') ==# 'foo'
  end

  it 'should override existing key mappings if overridep is true'
    inoremap x  FOO
    call smartinput#define_rule({'at': '', 'char': 'x', 'input': 'BAR',
    \                          'mode': 'i'})
    cnoremap y  foo
    call smartinput#define_rule({'at': '', 'char': 'y', 'input': 'bar',
    \                          'mode': ':'})
    call smartinput#map_trigger_keys(!0)

    Expect b:get_lhss('imap') ==# [
    \   '<C-H>',
    \   '<CR>',
    \   '<NL>',
    \   'x',
    \ ]
    Expect maparg('x', 'i') !=# 'FOO'
    Expect b:get_lhss('cmap') ==# [
    \   '<C-H>',
    \   '<CR>',
    \   '<NL>',
    \   'y',
    \ ]
    Expect maparg('y', 'c') !=# 'foo'
  end
end
