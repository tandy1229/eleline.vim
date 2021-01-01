" =============================================================================
" Filename: eleline.vim
" Author: Liu-Cheng Xu
" URL: https://github.com/liuchengxu/eleline.vim
" Fork: tandy1229
" License: MIT License
" =============================================================================
scriptencoding utf-8
if exists('g:loaded_eleline') || v:version < 700
  finish
endif
let g:loaded_eleline = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

let s:font = get(g:, 'eleline_powerline_fonts', get(g:, 'airline_powerline_fonts', 0))
let s:gui = has('gui_running')

function! ElelinePaste() abort
  return &paste ? 'PASTE ' : ''
endfunction

function! ElelineFsize(f) abort
  let l:size = getfsize(expand(a:f))
  if l:size == 0 || l:size == -1 || l:size == -2
    return ''
  endif
  if l:size < 1024
    let size = l:size.' bytes'
  elseif l:size < 1024*1024
    let size = printf('%.1f', l:size/1024.0).'k'
  elseif l:size < 1024*1024*1024
    let size = printf('%.1f', l:size/1024.0/1024.0) . 'm'
  else
    let size = printf('%.1f', l:size/1024.0/1024.0/1024.0) . 'g'
  endif
  return '  '.size.' '
endfunction

function! ElelineCurFname() abort
  return &filetype ==# 'startify' ? '' : '  '.expand('%:p:t').' '
endfunction

function! s:is_tmp_file() abort
  if !empty(&buftype) | return 1 | endif
  if &previewwindow | return 1 | endif
  let filename = expand('%:p')
  if filename =~# '^/tmp' | return 1 | endif
  if filename =~# '^fugitive:' | return 1 | endif
  return index(['startify', 'vim-plug', 'gitcommit', 'defx', 'coc-explorer', 'vista', 'vista_kind'], &filetype) > -1
endfunction

" Reference: https://github.com/chemzqm/vimrc/blob/master/statusline.vim
function! ElelineGitBranch(...) abort
  if s:is_tmp_file()
    return ''
  endif
  let coc_branch = get(g:,'coc_git_status','')
  if exists('g:coc_git_status')
    return g:coc_git_status
  endif
  return ''
endfunction

function! ElelineGitStatus() abort
  let l:summary = [0, 0, 0]
  if exists('b:coc_git_status')
    let hunks = get(b:, 'coc_git_status', '')
    for val in split(hunks)
      if val[0] is# '+'
        let l:summary[0] = val[1:] + 0
      elseif val[0] is# '~'
        let l:summary[1] = val[1:] + 0
      elseif val[0] is# '-'
        let l:summary[2] = val[1:] + 0
      endif
    endfor
  elseif exists('b:sy')
    let l:summary = b:sy.stats
  elseif exists('b:gitgutter.summary')
    let l:summary = b:gitgutter.summary
  endif
  if max(l:summary) > 0
    return '  '.'+'.l:summary[0].' ~'.l:summary[1].' -'.l:summary[2].' '
  endif
  return ''
endfunction

function! ElelineVista() abort
  return !empty(get(b:, 'coc_current_function', '')) ? b:coc_current_function : ''
endfunction

function! ElelineNvimLsp() abort
  if s:is_tmp_file()
    return ''
  endif
  if luaeval('#vim.lsp.buf_get_clients() > 0')
    let l:lsp_status = luaeval("require('lsp-status').status()")
    return empty(l:lsp_status) ? '' : s:fn_icon.l:lsp_status
  endif
  return ''
endfunction

function! ElelineCoc() abort
  if s:is_tmp_file()
    return ''
  endif
  if get(g:, 'coc_enabled', 0)
    return coc#status().' '
  endif
  return ''
endfunction

function! ElelineScroll() abort
  if s:is_tmp_file()
    return ''
  endif
  if !exists("*ScrollStatus")
    return ''
  endif
  return ScrollStatus()
endfunction

function! s:def(fn) abort
  return printf('%%#%s#%%{%s()}%%*', a:fn, a:fn)
endfunction

" https://github.com/liuchengxu/eleline.vim/wiki
function! s:StatusLine() abort
  let l:curfname = s:def('ElelineCurFname').'%m%r'
  let l:paste = s:def('ElelinePaste')
  let l:branch = s:def('ElelineGitBranch')
  let l:status = s:def('ElelineGitStatus')
  let l:tags = '%{exists("b:gutentags_files") ? gutentags#statusline() : ""} '
  let l:coc = s:def('ElelineCoc')
  let l:lsp = ''
  let l:scroll = '%{ElelineScroll()}%*'
  let l:vista = '%#ElelineVista#%{ElelineVista()}%*'
  if empty(get(b:, 'vista_nearest_method_or_function', '')) && has('nvim-0.5')
      let l:lsp = '%{ElelineNvimLsp()}'
  endif
  if get(g:, 'eleline_slim', 0)
    return l:prefix.'%<'.l:common
  endif
  let l:fsize = '%#ElelineFsize#%{ElelineFsize(@%)}%*'
  let l:m_r_f = '%#Eleline7# '.(s:is_tmp_file()?'':'%y %*')
  let l:pos = '%#Eleline8# '.(s:font?"":'').(s:is_tmp_file()?'':'%P %l/%L:%c%V %*')
  let l:enc = ' %{&fenc != "" ? &fenc : &enc} | %{&bomb ? ",BOM " : ""}'
  let l:ff = '%{&ff} %*'
  let l:pct = '%#Eleline9# %P %*'
  if l:scroll != ''
    let l:pct = ''
    let l:scroll = '%#Eleline7#%*'.l:scroll
  endif
  let l:common = l:paste.l:curfname.' '.l:branch.l:status.l:tags.l:coc.l:lsp.l:vista
  return l:common.'%='.l:m_r_f.l:pos.l:scroll.l:fsize
endfunction

let s:colors = {
            \   140 : '#af87d7', 149 : '#99cc66', 160 : '#d70000',
            \   171 : '#d75fd7', 178 : '#ffbb7d', 184 : '#ffe920',
            \   208 : '#ff8700', 232 : '#333300', 197 : '#cc0033',
            \   214 : '#ffff66', 124 : '#af3a03', 172 : '#b57614',
            \   32  : '#57c7ff', 89  : '#6c3163',
            \
            \   235 : '#262626', 236 : '#303030', 237 : '#3a3a3a',
            \   238 : '#444444', 239 : '#4e4e4e', 240 : '#585858',
            \   241 : '#606060', 242 : '#666666', 243 : '#767676',
            \   244 : '#808080', 245 : '#8a8a8a', 246 : '#949494',
            \   247 : '#9e9e9e', 248 : '#a8a8a8', 249 : '#b2b2b2',
            \   250 : '#bcbcbc', 251 : '#c6c6c6', 252 : '#d0d0d0',
            \   253 : '#dadada', 254 : '#e4e4e4', 255 : '#eeeeee',
            \ }

function! s:extract(group, what, ...) abort
  if a:0 == 1
    return synIDattr(synIDtrans(hlID(a:group)), a:what, a:1)
  else
    return synIDattr(synIDtrans(hlID(a:group)), a:what)
  endif
endfunction

if !exists('g:eleline_background')
  let s:normal_bg = s:extract('Normal', 'bg', 'cterm')
  if s:normal_bg >= 233 && s:normal_bg <= 243
    let s:bg = s:normal_bg
  else
    let s:bg = 235
  endif
else
  let s:bg = g:eleline_background
endif

" Don't change in gui mode
if has('termguicolors') && &termguicolors
  let s:bg = 235
endif

function! s:hi(group, dark, light, ...) abort
  let [fg, bg] = &background ==# 'dark' ? a:dark : a:light

  if empty(bg)
    if &background ==# 'light'
      let reverse = s:extract('StatusLine', 'reverse')
      let ctermbg = s:extract('StatusLine', reverse ? 'fg' : 'bg', 'cterm')
      let ctermbg = empty(ctermbg) ? 237 : ctermbg
      let guibg = s:extract('StatusLine', reverse ? 'fg': 'bg' , 'gui')
      let guibg = empty(guibg) ? s:colors[237] : guibg
    else
      let ctermbg = bg
      let guibg = s:colors[bg]
    endif
  else
    let ctermbg = bg
    let guibg = s:colors[bg]
  endif
  execute printf('hi %s ctermfg=%d guifg=%s ctermbg=%d guibg=%s',
                \ a:group, fg, s:colors[fg], ctermbg, guibg)
  if a:0 == 1
    execute printf('hi %s cterm=%s gui=%s', a:group, a:1, a:1)
  endif
endfunction

function! s:hi_statusline() abort
  call s:hi('ElelineFsize'      , [250 , s:bg+3] , [235 , ''] )
  call s:hi('ElelineCurFname'   , [171 , s:bg+4] , [171 , '']     , 'bold' )
  call s:hi('ElelineGitBranch'  , [149 , s:bg] , [89  , '']     , 'bold' )
  call s:hi('ElelineGitStatus'  , [208 , s:bg] , [89  , ''])
  call s:hi('ElelineVista'      , [178 , s:bg] , [149 , ''])
  call s:hi('ElelineCoc'        , [171 , s:bg] , [171 , '']     , 'bold' )

  if &background ==# 'dark'
    call s:hi('StatusLine' , [140 , s:bg], [140, ''] , 'none')
  endif

  call s:hi('Eleline7'      , [249 , s:bg+1], [237, ''] )
  call s:hi('Eleline8'      , [250 , s:bg+2], [238, ''] )
  call s:hi('Eleline9'      , [251 , s:bg+6], [239, ''] )
endfunction

function! s:InsertStatuslineColor(mode) abort
  if a:mode ==# 'i'
    call s:hi('ElelineCurFname' , [89, 32] , [251, 89])
  elseif a:mode ==# 'r'
    call s:hi('ElelineCurFname' , [232, 160], [232, 160])
  else
    call s:hi('ElelineCurFname' , [232, 178], [89, ''])
  endif
endfunction

" Note that the "%!" expression is evaluated in the context of the
" current window and buffer, while %{} items are evaluated in the
" context of the window that the statusline belongs to.
function! s:SetStatusLine(...) abort
  call ElelineGitBranch(1)
  let &l:statusline = s:StatusLine()
  " User-defined highlightings shoule be put after colorscheme command.
  call s:hi_statusline()
endfunction

if exists('*timer_start')
  call timer_start(100, function('s:SetStatusLine'))
else
  call s:SetStatusLine()
endif

augroup eleline
  autocmd!
  autocmd User GitGutter,Startified,LanguageClientStarted call s:SetStatusLine()
  " Change colors for insert mode
  autocmd InsertLeave * call s:hi('ElelineCurFname', [232, 140], [89, ''])
  autocmd InsertEnter,InsertChange * call s:InsertStatuslineColor(v:insertmode)
  autocmd BufWinEnter,ShellCmdPost,BufWritePost * call s:SetStatusLine()
  autocmd FileChangedShellPost,ColorScheme * call s:SetStatusLine()
  autocmd FileReadPre,ShellCmdPost,FileWritePost * call s:SetStatusLine()
augroup END

let &cpoptions = s:save_cpo
unlet s:save_cpo
