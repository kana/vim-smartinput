" NB: MacVim defines several key mappings such as <D-v> by default.
" The key mappings are defined from the core, not from any runtime file.
" So that the key mappings are always defined even if Vim is invoked by
" "vim -u NONE" etc.  Remove the kay mappings to ensure that there is no key
" mappings, because some tests in this file assume such state.
imapclear

inoremap (  (((

call vspec#hint({'scope': 'smartpunc#scope()', 'sid': 'smartpunc#sid()'})

describe 'Start-up'
  it 'should preverse existing key mappings prior to the default key mappings'
    redir => s
    0 verbose imap
    redir END
    let lhss = split(s, '\n')
    call map(lhss, 'substitute(v:val, ''\v\S+\s+(\S+)\s+.*'', ''\1'', ''g'')')
    call sort(lhss)

    Expect lhss ==# [
    \   '"',
    \   '%',
    \   '&',
    \   '''',
    \   '(',
    \   ')',
    \   '*',
    \   '+',
    \   '-',
    \   '/',
    \   '<',
    \   '<BS>',
    \   '<C-H>',
    \   '<CR>',
    \   '<NL>',
    \   '=',
    \   '>',
    \   '[',
    \   ']',
    \   '^',
    \   '`',
    \   '{',
    \   '|',
    \   '}',
    \   '~',
    \ ]
    Expect maparg('(', 'i') ==# '((('
  end
end
