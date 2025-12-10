# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"
# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
git
sudo
zsh-completions 
zsh-autosuggestions 
zsh-syntax-highlighting
fzf
fzf-tab
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/ihxnan/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/ihxnan/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/home/ihxnan/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/ihxnan/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# ==============================================
# 快捷键设置(bindkey)
# ==============================================

# 将 Ctrl+Y 键绑定为接受 zsh-autosuggestions 插件的自动建议
# 当插件提示命令建议时，按 Ctrl+Y 可快速采纳建议内容
bindkey '^Y' autosuggest-accept

# ==============================================
# 环境变量配置 (Environment Variables)
# ==============================================

# 设置默认编辑器为 neovim
export EDITOR=/usr/bin/nvim

# 设置语言环境为美式英语
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# 将用户自定义二进制目录添加到系统路径
# 使 ~/bin 目录下的可执行文件无需绝对路径即可运行
export PATH=/opt/cuda/bin:$PATH:~/bin/:~/blender-git/build_linux/bin

# 设置默认浏览器为 chromium
export BROWSER=/usr/bin/chromium

# zsh-autosuggestions
export ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# ubunut云服务器
export yun='ubuntu@106.53.202.12'

# ==============================================
# 命令别名配置 (Aliases)
# ==============================================

# 清屏命令
# 替代默认 clear 命令，输入 c 即可清屏
alias c=clear

# 系统更新命令
# 执行 Arch Linux 系统全面更新
# sudo pacman -Syyu: 强制刷新软件源并升级所有包
alias g='~/bin/g'

# 终端文件管理器快速启动
# 快速启动 ranger 终端文件管理器
alias jk=ranger

# Git 日志图形化展示
# 以简洁图形化方式显示所有分支的提交历史
# --oneline: 单行显示提交信息
# --graph: 显示分支合并图形
# --decorate: 显示分支标签信息
# --all: 显示所有分支
alias graph='git log --oneline --graph --decorate --all'

# 详细列表显示
# 显示当前目录所有文件（包括隐藏文件）的详细信息
alias l='ls -al'

# LeetCode 笔记快速打开
# 快速用 neovim 打开 leetcode 笔记文件
alias lt='nvim leetcode.nvim'

# 退出终端
# 快速退出当前终端会话
alias q=exit

# 系统信息展示
# 快速执行 neofetch，显示系统信息和 Logo
alias s='fastfetch | lolcat'
alias n='nvidia-smi | lolcat'

# 增强python
alias ip=ipython

# hexo 预览
alias pre='hexo clean && hexo server'

# hexo 提交
alias push='hexo clean && hexo generate && hexo deploy && submit'

# nvcc 指定算力
alias nvcc='nvcc -arch=sm_89'

