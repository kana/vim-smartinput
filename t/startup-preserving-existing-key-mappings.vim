" NB: MacVim defines several key mappings such as <D-v> by default.
" The key mappings are defined from the core, not from any runtime file.
" So that the key mappings are always defined even if Vim is invoked by
" "vim -u NONE" etc.  Remove the kay mappings to ensure that there is no key
" mappings, because some tests in this file assume such state.
imapclear
cmapclear

inoremap (  (((
cnoremap <BS>  Backspace!!!

runtime! plugin/smartinput.vim

call vspec#hint({'scope': 'smartinput#scope()', 'sid': 'smartinput#sid()'})

describe 'Start-up'
  it 'should preverse existing key mappings prior to the default key mappings'
    let f = {}
    function! f.get_lhss(map_command)
      redir => s
      execute '0 verbose' a:map_command
      redir END
      let lhss = split(s, '\n')
      call map(lhss, 'substitute(v:val, ''\v\S+\s+(\S+)\s+.*'', ''\1'', "g")')
      call sort(lhss)
      return lhss
    endfunction

    let lhssi = f.get_lhss('imap')

    Expect lhssi ==# [
    \   '"',
    \   '''',
    \   '(',
    \   ')',
    \   '<BS>',
    \   '<C-H>',
    \   '<CR>',
    \   '<NL>',
    \   '[',
    \   ']',
    \   '`',
    \   '{',
    \   '}',
    \ ]
    Expect maparg('(', 'i') ==# '((('

    let lhssc = f.get_lhss('cmap')

    Expect lhssc ==# [
    \   '<BS>',
    \   '<C-H>',
    \   '<CR>',
    \   '<NL>',
    \ ]
    Expect maparg('<BS>', 'c') ==# 'Backspace!!!'
  end
end
