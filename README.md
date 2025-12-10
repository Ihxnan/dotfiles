# dotfiles

> 个人化的开发环境配置集合

![预览图](https://img.shields.io/badge/OS-Arch_Linux-blue?style=flat-square)
![Shell](https://img.shields.io/badge/Shell-Zsh/Fish-yellow?style=flat-square)
![Editor](https://img.shields.io/badge/Editor-Neovim-green?style=flat-square)

## 📋 简介

这是一个精心配置的开发环境集合，包含了我在日常开发中使用的各种工具配置。通过这些配置文件，你可以快速搭建一个美观、高效的开发环境。

## ✨ 特性

- 🎨 **美观的终端** - Powerlevel10k主题 + Dracula配色
- ⚡ **高效的编辑器** - Neovim + Lua配置 + 丰富的插件生态
- 🐚 **现代Shell** - Fish Shell + 智能补全
- 🖥️ **多终端支持** - Alacritty/Kitty/Ghostty配置
- 💻 **IDE集成** - VSCode配置与Vim模式
- 🚀 **自动化脚本** - 一键安装和配置脚本

## 🖼️ 预览

### 终端界面
- Powerlevel10k主题提供清晰的状态显示
- 语法高亮和智能补全
- 丰富的Git集成

### 编辑器界面
- Neovim现代化的Lua配置
- 美观的配色方案和图标
- 强大的代码补全和导航功能

<<<<<<< HEAD
=======
## 🚀 快速开始

### 1. 克隆仓库

```bash
git clone git@github.com:Ihxnan/dotfiles.git ~/Github/dev
cd ~/Github/dev
```

### 2. 安装依赖

#### Arch Linux
```bash
# 运行安装脚本
./scripts/arch/install.sh

# 或手动安装主要组件
sudo pacman -S zsh fish neovim alacritty kitty
paru -S oh-my-zsh-git powerlevel10k
```

#### 其他系统
参考 `scripts/` 目录下的对应安装脚本

### 3. 配置环境

```bash
# 创建符号链接
./scripts/setup/symlinks.sh

# 配置Zsh
chsh -s $(which zsh)
```

### 4. 安装插件

```bash
# Neovim插件 (首次启动时自动安装)
nvim

# Vim插件
vim +PlugInstall +qall
```

## 📁 目录结构

```
dotfiles/
├── .config/          # 应用程序配置
│   ├── alacritty/    # Alacritty终端配置
│   ├── fish/         # Fish Shell配置
│   ├── nvim/         # Neovim配置
│   └── ...           # 其他应用配置
├── scripts/          # 安装和设置脚本
├── vscode/           # VSCode配置
├── .zshrc           # Zsh配置
├── .vimrc           # Vim配置
└── README.md        # 本文件
```

## ⚙️ 主要组件

### 终端和Shell

- **Zsh + Oh My Zsh + Powerlevel10k**
  - 强大的自动补全
  - Git集成
  - 丰富的主题和插件

- **Fish Shell**
  - 智能语法高亮
  - 基于历史的补全
  - 现代化的脚本语法

### 编辑器

- **Neovim**
  - Lua配置系统
  - LSP集成
  - 模块化插件管理

- **Vim**
  - 经典配置
  - 丰富的插件生态
  - 高效的键位映射

### 终端模拟器

- **Alacritty** - 高性能GPU加速终端
- **Kitty** - 功能丰富的终端模拟器
- **Ghostty** - 现代化终端体验

## 🎨 自定义

### 主题和配色

- 终端主题基于Dracula配色方案
- 支持亮色/暗色模式切换
- 可自定义字体和透明度

### 插件管理

- Neovim使用lazy.nvim
- Vim使用vim-plug
- Zsh使用Oh My Zsh插件系统

---

⭐ 如果这个项目对你有帮助，请给它一个星标！
