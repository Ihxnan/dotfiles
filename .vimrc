" __  ____   __  _   ___     _____ __  __ ____   ____
"|  \/  \ \ / / | \ | \ \   / /_ _|  \/  |  _ \ / ___|
"| |\/| |\ V /  |  \| |\ \ / / | || |\/| | |_) | |
"| |  | | | |   | |\  | \ V /  | || |  | |  _ <| |___
"|_|  |_| |_|   |_| \_|  \_/  |___|_|  |_|_| \_\\____|

" Author: @ihxnan

" =============================
" ====== 编辑器增强设置 ======
" =============================

" 显示设置
set encoding=utf-8          " 编码格式
set number                  " 显示行号
set relativenumber          " 显示相对行号（方便跳转）
set cursorline              " 高亮当前行
set termguicolors           " 启用真彩色支持（需要终端支持）
set background=dark         " 使用深色背景模式

" 缩进设置
set expandtab               " 将Tab转换为空格
set tabstop=4               " Tab显示为4个空格宽度
set shiftwidth=4            " 自动缩进时使用4个空格
set softtabstop=4           " 退格键一次删除4个空格
set autoindent              " 自动继承上一行缩进
set smartindent             " 智能缩进（适合代码编写）

" 搜索设置
set ignorecase              " 搜索时忽略大小写
set smartcase               " 如果搜索包含大写字母，则区分大小写

" 其他设置
set notimeout               " 防止组合键超时问题

" ==============================
" ==========快捷键映射==========
" ==============================

" 在插入模式下用 jk 代替 Esc 键
imap jk <Esc>
" 用空格键代替 : 进入命令模式
nmap <space> :
" 外部复制操作
nmap Y "+y
" shift + j 快速下移
nmap J 5j
" shift + k 快速上移
nmap K 5kjk

" 插件快捷键
" NERDTree
" 使用 Ctrl+e 切换文件树
map <silent> <C-e> :NERDTreeToggle<CR>

" markdown
" markdown : Ctrl + p 打开实时预览
nmap <C-p> <Plug>MarkdownPreview<CR>

" vim-autoformat
noremap <C-i> :Autoformat<CR>

" =============================
" ======== 插件列表 ===========
" =============================

" 初始化插件系统（使用vim-plug）
call plug#begin('~/.vim/')

" 优化开始界面
Plug 'mhinz/vim-startify'

" 文件树导航插件
Plug 'scrooloose/nerdtree'

" 状态栏美化插件
Plug 'vim-airline/vim-airline'

" 经典配色方案
Plug 'w0ng/vim-hybrid'

" 小图标
Plug 'ryanoasis/vim-devicons'

" 透明效果
Plug 'tribela/vim-transparent'

" 自动补全括号/引号
Plug 'chun-yang/auto-pairs'

" 彩虹括号
Plug 'kien/rainbow_parentheses.vim'

" 缩进效果
Plug 'yggdroot/indentline'

" 快速注释插件（使用gcc注释单行）
Plug 'tpope/vim-commentary'

" markdown实时预览
Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && npx --yes yarn install' }

" 自动格式化代码
Plug 'vim-autoformat/vim-autoformat'

" 插件列表结束
call plug#end()

" =============================
" ======= 插件配置 ==========
" =============================

" 主题配色配置
colorscheme hybrid          " 使用 hybrid 配色方案

" 配置auto-pairs对尖括号的自动补全
let g:AutoPairs = {
            \ '(': ')',
            \ '[': ']',
            \ '{': '}',
            \ '"': '"',
            \ "'": "'",
            \ '`': '`'
            \}
let g:AutoPairsMultilineClose = 1

" rainbow_parentheses 插件配置
" 颜色配置
let g:rbpt_colorpairs = [
            \ ['brown',       'RoyalBlue3'],
            \ ['Darkblue',    'SeaGreen3'],
            \ ['darkgray',    'DarkOrchid3'],
            \ ['darkgreen',   'firebrick3'],
            \ ['darkcyan',    'RoyalBlue3'],
            \ ['darkred',     'SeaGreen3'],
            \ ['darkmagenta', 'DarkOrchid3'],
            \ ['brown',       'firebrick3'],
            \ ['gray',        'RoyalBlue3'],
            \ ['black',       'SeaGreen3'],
            \ ['darkmagenta', 'DarkOrchid3'],
            \ ['Darkblue',    'firebrick3'],
            \ ['darkgreen',   'RoyalBlue3'],
            \ ['darkcyan',    'SeaGreen3'],
            \ ['darkred',     'DarkOrchid3'],
            \ ['red',         'firebrick3'],
            \ ]
let g:rbpt_max = 16
let g:rbpt_loadcmd_toggle = 0
au VimEnter * RainbowParenthesesToggle
au Syntax * RainbowParenthesesLoadRound
au Syntax * RainbowParenthesesLoadSquare
au Syntax * RainbowParenthesesLoadBraces

" markdown
let g:mkdp_auto_start = 1

" autoformat 配置
let g:formatdef_clangformat_microsoft = '"clang-format -style microsoft -"'
let g:formatters_cpp = ['clangformat_microsoft']
let g:python3_host_prog = "/usr/bin/python3"
