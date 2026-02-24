#!/usr/bin/env bash

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Dotfiles 目录: $DOTFILES_DIR"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Dotfiles 依赖安装脚本${NC}"
echo -e "${BLUE}=========================================${NC}"

if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}错误: 请不要使用 root 用户运行此脚本！${NC}"
    exit 1
fi

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}第 1 步: 更新系统${NC}"
echo -e "${BLUE}=========================================${NC}"
sudo pacman -Syu --noconfirm

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}第 2 步: 安装基础依赖${NC}"
echo -e "${BLUE}=========================================${NC}"
echo -e "${YELLOW}安装窗口管理器和桌面环境...${NC}"
sudo pacman -S --noconfirm i3-wm i3-gaps polybar rofi dunst picom feh

echo -e "${YELLOW}安装终端...${NC}"
sudo pacman -S --noconfirm alacritty kitty

echo -e "${YELLOW}安装音乐相关软件...${NC}"
sudo pacman -S --noconfirm mpd ncmpcpp cava playerctl

echo -e "${YELLOW}安装系统工具...${NC}"
sudo pacman -S --noconfirm btop fastfetch nvidia-utils eza fzf

echo -e "${YELLOW}安装编辑器...${NC}"
sudo pacman -S --noconfirm neovim

echo -e "${YELLOW}安装截图工具...${NC}"
sudo pacman -S --noconfirm flameshot

echo -e "${YELLOW}安装其他工具...${NC}"
sudo pacman -S --noconfirm lolcat ipython

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}第 3 步: 安装 Shell 和插件${NC}"
echo -e "${BLUE}=========================================${NC}"
echo -e "${YELLOW}安装 Zsh...${NC}"
sudo pacman -S --noconfirm zsh

echo -e "${YELLOW}检查 Oh My Zsh...${NC}"
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo -e "${YELLOW}安装 Oh My Zsh...${NC}"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo -e "${GREEN}Oh My Zsh 已安装${NC}"
fi

echo -e "${YELLOW}检查 Powerlevel10k...${NC}"
if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]]; then
    echo -e "${YELLOW}安装 Powerlevel10k...${NC}"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
else
    echo -e "${GREEN}Powerlevel10k 已安装${NC}"
fi

echo -e "${YELLOW}安装 Zsh 插件...${NC}"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
else
    echo -e "${GREEN}zsh-autosuggestions 已安装${NC}"
fi

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
else
    echo -e "${GREEN}zsh-syntax-highlighting 已安装${NC}"
fi

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-completions" ]]; then
    git clone https://github.com/zsh-users/zsh-completions $ZSH_CUSTOM/plugins/zsh-completions
else
    echo -e "${GREEN}zsh-completions 已安装${NC}"
fi

if [[ ! -d "$ZSH_CUSTOM/plugins/fzf-tab" ]]; then
    git clone https://github.com/Aloxaf/fzf-tab $ZSH_CUSTOM/plugins/fzf-tab
else
    echo -e "${GREEN}fzf-tab 已安装${NC}"
fi

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}第 4 步: 安装 AUR 软件包${NC}"
echo -e "${BLUE}=========================================${NC}"
echo -e "${YELLOW}安装 matugen...${NC}"
paru -S --noconfirm matugen

echo -e "${YELLOW}安装 yazi...${NC}"
paru -S --noconfirm yazi

echo -e "${YELLOW}安装 lazygit...${NC}"
paru -S --noconfirm lazygit

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}第 5 步: 安装其他依赖${NC}"
echo -e "${BLUE}=========================================${NC}"
echo -e "${YELLOW}安装 Neovim 依赖...${NC}"
sudo pacman -S --noconfirm npm python-pip tree-sitter-cli bat

echo -e "${YELLOW}安装锁屏工具...${NC}"
paru -S --noconfirm i3lock-color

echo -e "${YELLOW}安装 SSH 文件系统...${NC}"
sudo pacman -S --noconfirm sshfs

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}第 6 步: 创建必要的目录${NC}"
echo -e "${BLUE}=========================================${NC}"
mkdir -p ~/Pictures/Screenshots
mkdir -p ~/.local/share/fcitx5/themes/Matugen
echo -e "${GREEN}目录创建完成${NC}"

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}第 7 步: 设置默认 Shell${NC}"
echo -e "${BLUE}=========================================${NC}"
if [[ "$SHELL" != "/bin/zsh" ]]; then
    echo -e "${YELLOW}将默认 Shell 更改为 Zsh...${NC}"
    chsh -s /bin/zsh
    echo -e "${GREEN}默认 Shell 已更改为 Zsh${NC}"
    echo -e "${YELLOW}请重新登录或重启终端以生效${NC}"
else
    echo -e "${GREEN}默认 Shell 已是 Zsh${NC}"
fi

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}第 8 步: 执行 symlink.sh${NC}"
echo -e "${BLUE}=========================================${NC}"
if [[ -f "$DOTFILES_DIR/symlink.sh" ]]; then
    echo -e "${YELLOW}执行 symlink.sh...${NC}"
    bash "$DOTFILES_DIR/symlink.sh"
else
    echo -e "${RED}错误: symlink.sh 不存在！${NC}"
    exit 1
fi

echo -e "${BLUE}=========================================${NC}"
echo -e "${GREEN}✓ 所有依赖安装完成！${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""
echo -e "${GREEN}提示：${NC}"
echo "1. 请重新登录或重启终端以应用 Zsh 配置"
echo "2. 运行 'nvim' 打开 Neovim，插件会自动安装"
echo ""
echo -e "${YELLOW}注意：${NC}"
echo "- 如果遇到 Conda 初始化错误，可以删除 .zshrc 中的 Conda 相关代码"
