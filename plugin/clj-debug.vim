" clj-debug.vim - A minimal port of the CIDER debugger for VIM
" Version:     0.1
" Maintainer: Fed Reggiardo <fedreg@me.com>

let g:nrepl_session_id = 0

function! GetCurrentSessionId()
  if !g:nrepl_session_id
    try
      let res = fireplace#clj().Message({
	    \'op': 'eval', 
	    \'code': '(inc 1)'
	    \}, v:t_list)
      let id = res[0].session
      let g:nrepl_session_id = id
      return id
    catch /^Fireplace:.*/
      echom "Clj-Debug:" v:exception
    endtry
  endif
endfunction

" function! DebuggerUserInput(key, in) abort
"   try
"     fireplace#clj().Message({
" 	  \ 'op': 'debug-input',
" 	  \ 'key': a:key,
" 	  \ 'input': a:in,
" 	  \ })
"   catch /^Fireplace:.*/
"     echom "Clj-Debug:" v:exception
"   endtry
" endfunction

function! CheckFireplaceConn()
  try
    if fireplace#clj().HasOp("eval")
      return 1
    endif
  catch /^Fireplace:.*/
    echom "Clj-Debug:" v:exception
    return 0
  endtry
endfunction

function! GetCurrentBuffNs()
  let msg = fireplace#clj().BufferNs()
  return msg
endfunction

function! FireplaceEval(cmd)
  if CheckFireplaceConn()
    try
      " let res = fireplace#clj().Query(a:cmd)
      let ns  = GetCurrentBuffNs()
      let res = fireplace#clj().Message({
	    \'op': 'eval', 
	    \'code': a:cmd, 
	    \'ns': ns
	    \ }, v:t_list)
      " hard coded for experimentation
      " call DebugUserInput('n', 'n') 
      echom res
    catch /^Fireplace:.*/
      echom v:exception
      return 0
    endtry
  endif
endfunction

function! Instrument()
    let cursor_pos = getpos('.')
    "search backwards for 'defn', 
    "then forwards for the end param vector,
    "then insert '#dbg' in line below,
    "then eval fn"
    execute 'silent normal! ' . "?defn\r/]\r"
    execute 'silent normal! ' . "o#dbg"
    execute 'silent normal! ' . "?(defn\rcpp"
endfunction

function! Unstrument()
    let cursor_pos = getpos('.')
    "search backwards for 'defn', 
    "then forwards for the '#dbg' tag,
    "then delete that line,
    "then eval fn
    execute 'silent normal! ' . "?defn\r/#dbg\r"
    execute 'silent normal! ' . "dd"
    execute 'silent normal! ' . "?(defn\rcpp"
endfunction

function! InitDebugger()
  let session_id  = GetCurrentSessionId()
  try
    let msg = fireplace#clj().Message({
	  \'op': 'init-debugger', 
          \'session': session_id
	  \})
    return 1
  catch /^Fireplace:.*/
    echom v:exception
    return 0
  endtry
endfunction

function! GetInstrumentedDefs()
  let ns  = GetCurrentBuffNs()
  let msg = fireplace#clj().Message({
	\'op':'debug-instrumented-defs', 
	\'ns': ns, 
	\'session': g:nrepl_session_id
	\}, v:t_list)
  echom msg[0].list
endfunction!

command! -nargs=0 CljDebugInstrument call Instrument()
command! -nargs=0 CljDebugUnstrument call Unstrument()
command! -nargs=1 CljDebugEval       call FireplaceEval(<q-args>)
command! -nargs=0 CljDebugInit       call InitDebugger()
command! -nargs=0 CljDebugList       call GetInstrumentedDefs()
command! -nargs=0 CljDebugCurrBuff   call GetCurrentBuffNs()
