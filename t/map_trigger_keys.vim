let g:smartpunc_no_default_key_mappings = !0

runtime! plugin/smartpunc.vim

call vspec#hint({'scope': 'smartpunc#scope()', 'sid': 'smartpunc#sid()'})

describe 'smartpunc#map_trigger_keys'
  before
    new

    function! b:get_lhss()
      redir => s
      0 verbose imap
      redir END
      let lhss = split(s, '\n')
      call map(lhss, 'substitute(v:val, ''\v\S+\s+(\S+)\s+.*'', ''\1'',''g'')')
      call sort(lhss)
      return lhss
    endfunction

    imapclear
    call smartpunc#clear_rules()
  end

  after
    close!
  end

  it 'should not map anything but "alias" ones if there is no rule'
    call smartpunc#map_trigger_keys()

    Expect b:get_lhss() ==# [
    \   '<C-H>',
    \   '<CR>',
    \   '<NL>',
    \ ]
  end

  it 'should not override existing key mappings if overridep is omitted'
    inoremap x  FOO
    call smartpunc#define_rule({'at': '', 'char': 'x', 'input': 'BAR'})
    call smartpunc#map_trigger_keys()

    Expect b:get_lhss() ==# [
    \   '<C-H>',
    \   '<CR>',
    \   '<NL>',
    \   'x',
    \ ]
    Expect maparg('x', 'i') ==# 'FOO'
  end

  it 'should not override existing key mappings if overridep is false'
    inoremap x  FOO
    call smartpunc#define_rule({'at': '', 'char': 'x', 'input': 'BAR'})
    call smartpunc#map_trigger_keys(!!0)

    Expect b:get_lhss() ==# [
    \   '<C-H>',
    \   '<CR>',
    \   '<NL>',
    \   'x',
    \ ]
    Expect maparg('x', 'i') ==# 'FOO'
  end

  it 'should override existing key mappings if overridep is true'
    inoremap x  FOO
    call smartpunc#define_rule({'at': '', 'char': 'x', 'input': 'BAR'})
    call smartpunc#map_trigger_keys(!0)

    Expect b:get_lhss() ==# [
    \   '<C-H>',
    \   '<CR>',
    \   '<NL>',
    \   'x',
    \ ]
    Expect maparg('x', 'i') !=# 'FOO'
  end
end
