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
syntax on
filetype on
filetype plugin indent on

" ==============================
" ==========快捷键映射==========
" ==============================

" 在插入模式下用 jk 代替 Esc 键
imap jk <Esc>
" 外部复制操作
nmap Y "+y
" shift + j 快速下移
nmap J 5j
" shift + k 快速上移
nmap K 5k

nmap j gj
nmap k gk

