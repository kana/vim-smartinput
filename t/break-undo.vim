" NB: MacVim defines several key mappings such as <D-v> by default.
" The key mappings are defined from the core, not from any runtime file.
" So that the key mappings are always defined even if Vim is invoked by
" "vim -u NONE" etc.  Remove the kay mappings to ensure that there is no key
" mappings, because some tests in this file assume such state.
imapclear
cmapclear

runtime! plugin/smartinput.vim

call vspec#hint({'scope': 'smartinput#scope()', 'sid': 'smartinput#sid()'})
set backspace=indent,eol,start
filetype plugin indent on
syntax enable

describe 'g:smartinput_break_undo'
  before
    call smartinput#clear_rules()
    new

    function! b:.test_keys_undo(name, pre_input, table)
      let n = a:name
      for i in range(len(a:table))
        let [input, expects] = a:table[i]
        normal! gg0D
        call feedkeys('a' . a:pre_input, 'tx')
        call feedkeys(input, 'tx')
        for j in range(len(expects))
          let expected = expects[j]
          Expect [n, i, j, getline(1, line('$'))] ==# [n, i, j, [expected]]
          normal! u
        endfor
      endfor
    endfunction

    function! b:.test_no_break_undo()
      " define with "i_CTRL-G_U"
      call smartinput#define_default_rules()

      call b:.test_keys_undo('*', 'call ', [
      \  ['a(foo)bar', ['call (foo)bar', 'call ']],
      \ ])

      call b:.test_keys_undo('*', 'echo ', [
      \  ['a(foo)bar', ['echo (foo)bar', 'echo ']],
      \  ['a[foo]bar', ['echo [foo]bar', 'echo ']],
      \  ['a{foo}bar', ['echo {foo}bar', 'echo ']],
      \  ["a'foo' bar", ["echo 'foo' bar", "echo "]],
      \  ['a"foo" bar', ['echo "foo" bar', 'echo ']],
      \  ['a`foo` bar', ['echo `foo` bar', 'echo ']],
      \  ["a'''foo' bar", ["echo '''foo''' bar", 'echo ']],
      \  ['a"""foo" bar', ['echo """foo""" bar', 'echo ']],
      \  ['a```foo` bar', ['echo ```foo``` bar', 'echo ']],
      \ ])

      setfiletype python
      call b:.test_keys_undo('Python string', 'echo ', [
      \  ["au'foo' bar", ["echo u'foo' bar", "echo "]],
      \ ])

      setfiletype lisp
      call b:.test_keys_undo('Lisp quote', '(define ', [
      \  ['afiletype "''lisp', ['(define filetype "''lisp''")', '(define )']],
      \ ])

      setfiletype vim
      call b:.test_keys_undo('strong quote', 'echo ', [
      \  ["a'foo\\' bar", ["echo 'foo\\' bar", "echo "]],
      \ ])
    endfunction
  end

  after
    close!
  end

  it 'should define the default rules with no-break-undo, if it is not exists'
    unlet! g:smartinput_break_undo
    call b:.test_no_break_undo()
  end

  it 'should define the default rules with no-break-undo, if it is 0'
    let g:smartinput_break_undo = 0
    call b:.test_no_break_undo()
  end

  it 'should define the default rules with break-undo, if it is not 0'
    let g:smartinput_break_undo = !0

    " define without i_CTRL-G_U
    call smartinput#define_default_rules()

    call b:.test_keys_undo('*', 'echo ', [
    \  ['a(foo)bar', ['echo (foo)bar', 'echo (foo)', 'echo ()', 'echo ']],
    \  ['a[foo]bar', ['echo [foo]bar', 'echo [foo]', 'echo []', 'echo ']],
    \  ['a{foo}bar', ['echo {foo}bar', 'echo {foo}', 'echo {}', 'echo ']],
    \  ["a'foo' bar", ["echo 'foo' bar", "echo 'foo'", "echo ''", 'echo ']],
    \  ['a"foo" bar', ['echo "foo" bar', 'echo "foo"', 'echo ""', 'echo ']],
    \  ['a`foo` bar', ['echo `foo` bar', 'echo `foo`', 'echo ``', 'echo ']],
    \  ["a'''foo' bar", ["echo '''foo''' bar", "echo '''foo'''", "echo ''''''", "echo ''", 'echo ']],
    \  ['a"""foo" bar', ['echo """foo""" bar', 'echo """foo"""', 'echo """"""', 'echo ""', 'echo ']],
    \  ['a```foo` bar', ['echo ```foo``` bar', 'echo ```foo```', 'echo ``````', 'echo ``', 'echo ']],
    \ ])

    setfiletype python
    call b:.test_keys_undo('Python string', 'echo ', [
    \  ["au'foo' bar", ["echo u'foo' bar", "echo u'foo'", "echo u''", 'echo ']],
    \ ])

    setfiletype lisp
    call b:.test_keys_undo('Lisp quote', '(define ', [
    \  ['afiletype "''lisp', ['(define filetype "''lisp''")', '(define filetype "''''")', '(define filetype "")', '(define )']],
    \ ])

    setfiletype vim
    call b:.test_keys_undo('strong quote', 'echo ', [
    \  ["a'foo\\' bar", ["echo 'foo\\' bar", "echo 'foo\\'", "echo ''", 'echo ']],
    \ ])
  end
end
