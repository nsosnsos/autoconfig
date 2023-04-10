syntax on
filetype plugin indent on
 
set fileencodings=utf-8,ucs-bom,gb18030,gbk,gb2312,cp936
set termencoding=utf-8
set encoding=utf-8
 
"--- system config ---
set number
set showcmd showmode
set ruler
set cursorline
set background=dark
set laststatus=2
set tabstop=4
set softtabstop=4
set shiftwidth=4
set history=50
set mouse=a
set expandtab
set noswapfile
"gqG formats the text starting from the current position and to the end of the file.
"It will automatically join consecutive lines when possible.
"You can place a blank line between two lines if you don't want those two to be joined together.
set textwidth=80
 
"--- search config ---
set ignorecase smartcase
set incsearch hlsearch
set showmatch
 
"--- indent config ---
set autoindent smartindent cindent
set cinoptions={0,1s,t0,n-2,p2s,(03s,=.5s,>1s,=1s,:1s
 
"--- ctags setting ---
map <F5> :!ctags -R --c++-kinds=+p+l+x+c+d+e+f+g+m+n+s+t+u+v --fields=+iaSl --extra=+q .<CR><CR> :TlistUpdate<CR>
imap <F5> <ESC>:!ctags -R --c++-kinds=+p+l+x+c+d+e+f+g+m+n+s+t+u+v --fields=+iaSl --extra=+q .<CR><CR> :TlistUpdate<CR>
"--c++-kinds=+p  :为C++文件增加函数原型的标签
"--fields=+iaS   :在标签文件中加入继承信息(i)、类成员的访问控制信息(a)、以及函数的指纹(S)
"--extra=+q      :为标签增加类修饰符，用于对类成员补全
set tags=tags
set tags+=./tags
set tags+=/usr/include/tags

"--- omnicppcomplete setting ---
imap <F3> <C-X><C-O> "按下F3自动补全代码
imap <F2> <C-X><C-I> "按下F2根据头文件内关键字补全
set completeopt=menu,menuone "关掉智能补全时的预览窗口
let OmniCpp_MayCompleteDot = 1 "autocomplete with .
let OmniCpp_MayCompleteArrow = 1 "autocomplete with ->
let OmniCpp_MayCompleteScope = 1 "autocomplete with ::
let OmniCpp_SelectFirstItem = 2 "select first item (but don't insert)
let OmniCpp_NamespaceSearch = 2 "search namespaces in this and included files
let OmniCpp_ShowPrototypeInAbbr = 1 "show function prototype in popup window
let OmniCpp_GlobalScopeSearch=1 "enable the global scope search
let OmniCpp_DisplayMode=1 "Class scope completion mode: always show all members
let OmniCpp_ShowScopeInAbbr=1 "show scope in abbreviation and remove the last column
let OmniCpp_DefaultNamespaces=["std"]
let OmniCpp_ShowAccess=1
 
"--- Taglist setting ---
let Tlist_Ctags_Cmd='/usr/bin/ctags' "设置ctags命令路径
let Tlist_Use_Right_Window=1 "让窗口显示在右边
let Tlist_Show_One_File=0 "同时展示多个tags文件的函数列表
let Tlist_File_Fold_Auto_Close=1 "非当前文件的函数列表折叠隐藏
let Tlist_Exit_OnlyWindow=1 "当taglist是最后一个分割窗口时自动退出
let Tlist_Process_File_Always=1 "一直处理tags
let Tlist_Inc_Winwidth=0 "禁止更新vim窗口宽度
"let Tlist_Auto_Open=1 "自动打开taglist
let Tlist_Process_File_Always=1 "始终解析文件中的tag
 
"--- WinManager setting ---
let g:winManagerWindowLayout='FileExplorer|TagList' "设置我们要管理的插件
let g:persistentBehaviour=0 "所有编辑文件都关闭则退出vim
nmap wm :WMToggle<cr>
 
"--- MiniBufferExplorer ---
let g:miniBufExplMapWindowNavVim = 1 "按下Ctrl+h/j/k/l，可以切换到当前窗口的上下左右窗口
let g:miniBufExplMapWindowNavArrows = 1 "按下Ctrl+箭头，可以切换到当前窗口的上下左右窗口
let g:miniBufExplMapCTabSwitchBufs = 1 "启用以下两个功能：Ctrl+tab移到下一个buffer并在当前窗口打开；Ctrl+Shift+tab移到上一个buffer并在当前窗口打开；ubuntu好像不支持
let g:miniBufExplModSelTarget = 1 "不要在不可编辑内容的窗口（如TagList窗口）中打开选中的buffer
let g:miniBufExplMapCTabSwitchWindows = 1 "启用以下两个功能：Ctrl+tab移到下一个窗口；Ctrl+Shift+tab移到上一个窗口
let g:miniBufExplorerMoreThanOne = 0 "不允许多个miniBuf窗口
 
"--- fold setting ---
set foldmethod=syntax "用语法高亮来定义折叠
set foldlevel=100 "启动vim时不要自动折叠代码
set foldcolumn=5 "设置折叠栏宽度
 
"--- Cscope setting ---
if has("cscope")
set csprg=/usr/bin/cscope "指定用来执行cscope的命令
set csto=0 "设置cstag命令查找次序：0先找cscope数据库再找标签文件；1先找标签文件再找cscope数据库
set cst "同时搜索cscope数据库和标签文件
set cscopequickfix=s-,c-,d-,i-,t-,e- "使用QuickFix窗口来显示cscope查找结果
set nocsverb
if filereadable("./cscope.out") "若当前目录下存在cscope数据库，添加该数据库到vim
cs add ./cscope.out ./
elseif $CSCOPE_DB != "" "否则只要环境变量CSCOPE_DB不为空，则添加其指定的数据库到vim
cs add $CSCOPE_DB
endif
if filereadable("/usr/include/cscope.out")
cs add /usr/include/cscope.out /usr/include/
endif
set csverb
endif
map <F4> : !cscope -Rbkq<CR><CR> :cs add ./cscope.out .<CR><CR> :cs reset<CR>
imap <F4> <ESC>:!cscope -Rbkq<CR><CR> :cs add ./cscope.out .<CR><CR> :cs reset<CR> "将:cs find c等Cscope查找命令映射为<C-_>c等快捷键（按法是先按Ctrl+Shift+-, 然后很快再按下c）
nmap <C-_>s :cs find s <C-R>=expand("<cword>")<CR><CR> :copen<CR><CR>
nmap <C-_>g :cs find g <C-R>=expand("<cword>")<CR><CR>
nmap <C-_>d :cs find d <C-R>=expand("<cword>")<CR><CR> :copen<CR><CR>
nmap <C-_>c :cs find c <C-R>=expand("<cword>")<CR><CR> :copen<CR><CR>
nmap <C-_>t :cs find t <C-R>=expand("<cword>")<CR><CR> :copen<CR><CR>
nmap <C-_>e :cs find e <C-R>=expand("<cword>")<CR><CR> :copen<CR><CR>
nmap <C-_>f :cs find f <C-R>=expand("<cfile>")<CR><CR>
nmap <C-_>i :cs find i <C-R>=expand("<cfile>")<CR><CR> :copen<CR><CR>
