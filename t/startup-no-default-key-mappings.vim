" NB: MacVim defines several key mappings such as <D-v> by default.
" The key mappings are defined from the core, not from any runtime file.
" So that the key mappings are always defined even if Vim is invoked by
" "vim -u NONE" etc.  Remove the kay mappings to ensure that there is no key
" mappings, because some tests in this file assume such state.
imapclear

let g:smartpunc_no_default_key_mappings = !0

runtime! plugin/smartpunc.vim

call vspec#hint({'scope': 'smartpunc#scope()', 'sid': 'smartpunc#sid()'})

describe 'g:smartpunc_no_default_key_mappings'
  it 'should suppress to define the default key mappings'
    redir => s
    0 verbose imap
    redir END

    Expect substitute(s, '[\r\n]', '', 'g') ==# 'No mapping found'
    Expect Call('s:get_available_nrules') !=# []
  end
end
