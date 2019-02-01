" Copied from http://vim.wikia.com/wiki/Act_on_text_objects_with_custom_functions
" Adapted from tpope/vim-unimpaired
function! s:DoAction(algorithm,type)
  " backup settings that we will change
  let sel_save = &selection
  let cb_save = &clipboard
  " make selection and clipboard work the way we need
  set selection=inclusive clipboard-=unnamed clipboard-=unnamedplus
  " backup the unnamed register, which we will be yanking into
  let reg_save = @@
  " yank the relevant text, and also set the visual selection (which will be reused if the text
  " needs to be replaced)
  if a:type =~ '^\d\+$'
    " if type is a number, then select that many lines
    silent exe 'normal! V'.a:type.'$y'
  elseif a:type =~ '^.$'
    " if type is 'v', 'V', or '<C-V>' (i.e. 0x16) then reselect the visual region
    silent exe "normal! `<" . a:type . "`>y"
  elseif a:type == 'line'
    " line-based text motion
    silent exe "normal! '[V']y"
  elseif a:type == 'block'
    " block-based text motion
    silent exe "normal! `[\<C-V>`]y"
  else
    " char-based text motion
    silent exe "normal! `[v`]y"
  endif
  " call the user-defined function, passing it the contents of the unnamed register
  let repl = s:{a:algorithm}(@@)
  " if the function returned a value, then replace the text
  if type(repl) == 1
    " put the replacement text into the unnamed register, and also set it to be a
    " characterwise, linewise, or blockwise selection, based upon the selection type of the
    " yank we did above
    call setreg('@', repl, getregtype('@'))
    " relect the visual region and paste
    normal! gvp
  endif
  " restore saved settings and register value
  let @@ = reg_save
  let &selection = sel_save
  let &clipboard = cb_save
endfunction

function! s:ActionOpfunc(type)
  return s:DoAction(s:encode_algorithm, a:type)
endfunction

function! s:ActionSetup(algorithm)
  let s:encode_algorithm = a:algorithm
  let &opfunc = matchstr(expand('<sfile>'), '<SNR>\d\+_').'ActionOpfunc'
endfunction

function! s:MapAction(algorithm, key)
  exe 'nnoremap <buffer> <Plug>actions'.a:algorithm.' :<C-U>call <SID>ActionSetup("'.a:algorithm.'")<CR>g@'
  exe 'xnoremap <buffer> <Plug>actions'.a:algorithm.' :<C-U>call <SID>DoAction("'.a:algorithm.'",visualmode())<CR>'
  exe 'nnoremap <buffer> <Plug>actionsLine'.a:algorithm.' :<C-U>call <SID>DoAction("'.a:algorithm.'",v:count1)<CR>'
  exe 'nmap <buffer> '.a:key.' <Plug>actions'.a:algorithm
  exe 'xmap <buffer> '.a:key.' <Plug>actions'.a:algorithm
  exe 'nmap <buffer> '.a:key.a:key[strlen(a:key)-1].' <Plug>actionsLine'.a:algorithm
endfunction

function! s:Eval(str)
  call conjure#eval(a:str)
endfunction

if !exists('g:conjure_refresh_dirs')
  let g:conjure_refresh_dirs = ["src"]
endif

if !exists('g:conjure_refresh_args')
  let g:conjure_refresh_args = ""
endif

if !exists('g:conjure_logging')
  let g:conjure_logging = 0
endif

if !exists('g:conjure_eval_count')
  let g:conjure_eval_count = 0
endif

augroup conjure_bindings
  autocmd!

  autocmd FileType clojure command! -buffer -bar -nargs=0 ConjureList call conjure#list()
  autocmd FileType clojure command! -buffer -bar -nargs=0 ConjureShowLog call conjure#show_log()
  autocmd FileType clojure command! -buffer -bar -nargs=0 ConjureEvalFile call conjure#eval_file()
  autocmd FileType clojure command! -buffer -bar -nargs=0 ConjureEvalBuffer call conjure#eval_buffer()
  autocmd FileType clojure command! -buffer -bar -nargs=0 ConjureRunTests call conjure#run_tests()
  autocmd FileType clojure command! -buffer -bar -nargs=0 ConjureRunAllTests call conjure#run_all_tests()
  autocmd FileType clojure command! -buffer -bar -nargs=0 ConjureRefresh call conjure#refresh()
  autocmd FileType clojure command! -buffer -bar -nargs=0 ConjureRefreshAll call conjure#refresh_all()
  autocmd FileType clojure command! -buffer -bar -nargs=1 ConjureDoc call conjure#doc(<f-args>)
  autocmd FileType clojure command! -buffer -bar -nargs=1 ConjureGoToDefinition call conjure#go_to_definition(<f-args>)
  autocmd FileType clojure command! -buffer -bar -nargs=1 ConjureEval call conjure#eval(<f-args>)
  autocmd FileType clojure command! -buffer -bar -nargs=0 ConjureUpdateCompletions call conjure#update_completions()
  autocmd FileType clojure command! -buffer -bar -nargs=0 ConjureUpsertJob call conjure#upsert_job()
  autocmd FileType clojure command! -buffer -bar -nargs=0 ConjureStopJob call conjure#stop_job()
  autocmd FileType clojure command! -buffer -bar -nargs=0 ConjureRestartJob call conjure#restart_job()
  autocmd FileType clojure command! -buffer -bar -nargs=+ ConjureConnect call conjure#connect(<f-args>)
  autocmd FileType clojure command! -buffer -bar -nargs=1 ConjureDisconnect call conjure#disconnect(<f-args>)

  autocmd FileType clojure nnoremap <buffer> <localleader>rp :ConjureList<CR>
  autocmd FileType clojure nnoremap <buffer> <localleader>rl :ConjureShowLog<CR>

  autocmd FileType clojure call s:MapAction('Eval', 'cp')
  autocmd FileType clojure nnoremap <buffer> cpp :normal mscpaf<CR>`s
  autocmd FileType clojure nnoremap <buffer> <localleader>re :normal mscpaF<CR>`s

  autocmd FileType clojure nnoremap <buffer> <localleader>rf :ConjureEvalFile<CR>
  autocmd FileType clojure nnoremap <buffer> <localleader>rb :ConjureEvalBuffer<CR>

  autocmd FileType clojure nnoremap <buffer> <localleader>rt :ConjureRunTests<CR>
  autocmd FileType clojure nnoremap <buffer> <localleader>rT :ConjureRunAllTests<CR>

  autocmd FileType clojure nnoremap <buffer> <localleader>rr :ConjureRefresh<CR>
  autocmd FileType clojure nnoremap <buffer> <localleader>rR :ConjureRefreshAll<CR>

  autocmd FileType clojure nnoremap <buffer> K :ConjureDoc <C-R><C-W><CR>
  autocmd FileType clojure nnoremap <buffer> gd :ConjureGoToDefinition <C-R><C-W><CR>

  autocmd FileType clojure setlocal omnifunc=conjure#omnicomplete
  autocmd CursorHold * if &ft ==# 'clojure' | ConjureUpdateCompletions
augroup END
