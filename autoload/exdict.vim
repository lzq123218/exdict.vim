" File: autoload/exdict.vim
" Last Modified: 2012.04.15
" Author: yuratomo (twitter @yusetomo)

function! exdict#LoadSyntaxFromDict(file, name)
  exe 'syn keyword ' . a:name . ' ' . join(map(readfile(a:file, ''), ' substitute(v:val, "(.*$", "", "") '), ' ')
  exe 'hi default link ' . a:name . ' Function'
endfunction

function! s:UpdateRef(last_feed_keys)
  if !exists('b:dict_list')
    return -1
  endif

  let line = getline('.')
  if stridx(line, '(') != -1
    let keyword = substitute(line, '(.*$', '', '') . '('
  else
    let keyword = '\<'.expand('<cword>')
  endif
  if exists('b:last_keyword') && b:last_keyword == keyword
    return 0
  endif
  let b:last_keyword = keyword

  let dict_files = join(b:dict_list, ' ')
  let cmd = &grepprg . ' "' . keyword . '" ' . dict_files
  let b:func_def_list = split(system(cmd), "\n")
  let b:msg_adjust = - 4 - strlen(len(b:func_def_list))*2 - 12
  return 1
endfunction

function! exdict#ShowRef(direct,last_feed_keys)
  let direct = a:direct
  let ret = s:UpdateRef(a:last_feed_keys)
  if ret == -1
    return
  elseif ret == 1
    let direct = 0
  endif
  if len(b:func_def_list) <= 0
    echo 'no match item.'
    return
  endif

  let updateSubItem = 0
  if direct > 0 
    if b:subIndex == b:subItemNum -1
      let b:subIndex = 0
      if b:index < len(b:func_def_list) - 1
        let b:index = b:index + 1
        let updateSubItem = 1
      endif
    else
      let b:subIndex = b:subIndex + 1
    endif
  elseif direct < 0
    if b:subIndex == 0
      "let b:subIndex = xxx " can not resolve here.
      if b:index > 0
        let b:index = b:index - 1
        let updateSubItem = 1
      endif
    else
      let b:subIndex = b:subIndex - 1
    endif
  else
    let b:index = 0
    let updateSubItem = 1
    let b:subIndex = 0
  endif
  if a:last_feed_keys != ''
    call exdict#change_cmdheight()
  endif

  let max_ref_size = &columns + b:msg_adjust
  if updateSubItem == 1
    let parts = split(b:func_def_list[b:index], ':')
    let b:subItem = parts[len(parts) - 1]
    let b:subItemNum = strlen(b:subItem) / max_ref_size + 1
    if direct < 0
      if b:subIndex == 0
        let b:subIndex = b:subItemNum - 1  " resolve here
      endif
    endif
  endif

  let idx = b:index+1
  if b:subIndex >= b:subItemNum - 1
    let ref = strpart(b:subItem, b:subIndex*max_ref_size)
  else
    let ref = strpart(b:subItem, b:subIndex*max_ref_size, max_ref_size) 
  endif
  echom '('.idx.'/'.len(b:func_def_list).') '.ref
  redraw

  if a:last_feed_keys != ''
    call feedkeys(a:last_feed_keys, 'n')
    " vim's bug? cursor don't redraw...
    call feedkeys(" ", 'n')
    call feedkeys("\<BS>", 'n')
  endif
endfunction

function! exdict#change_cmdheight()
  if &cmdheight < 2
    let b:cmdheight_backup = &cmdheight
    let b:updatetime_backup = &updatetime
    let &cmdheight = 2
    let &updatetime = 100
    au! CursorHold <buffer> call exdict#restore_cmdheight()
  endif
endfunction

function! exdict#restore_cmdheight()
  au! CursorHold <buffer>
  if exists('b:updatetime_backup')
    let &updatetime = b:updatetime_backup
    let &cmdheight = b:cmdheight_backup
    unlet b:updatetime_backup
    unlet b:cmdheight_backup
  endif
endfunction

