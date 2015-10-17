" NB: MacVim defines several key mappings such as <D-v> by default.
" The key mappings are defined from the core, not from any runtime file.
" So that the key mappings are always defined even if Vim is invoked by
" "vim -u NONE" etc.  Remove the kay mappings to ensure that there is no key
" mappings, because some tests in this file assume such state.
imapclear
cmapclear

let g:panacea_no_default_key_mappings = !0

runtime! plugin/panacea.vim

call vspec#hint({'scope': 'panacea#scope()', 'sid': 'panacea#sid()'})

describe 'g:panacea_no_default_key_mappings'
  it 'should suppress to define the default key mappings'
    redir => si
    0 verbose imap
    redir END
    redir => sc
    0 verbose cmap
    redir END

    Expect substitute(si, '[\r\n]', '', 'g') ==# 'No mapping found'
    Expect substitute(sc, '[\r\n]', '', 'g') ==# 'No mapping found'
    Expect Ref('s:available_nrules') !=# []
  end
end
