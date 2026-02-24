#!/usr/bin/env bash

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Dotfiles 目录: $DOTFILES_DIR"

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 创建符号链接的函数
create_symlink() {
    local src="$1"
    local dest="$2"

    # 检查源文件是否存在
    if [[ ! -e "$src" ]]; then
        echo -e "${RED}✗ 源文件不存在: $src${NC}"
        return 1
    fi

    # 如果目标已存在，先备份
    if [[ -e "$dest" || -L "$dest" ]]; then
        echo -e "${YELLOW}⚠ 目标已存在: $dest${NC}"
        read -p "是否删除并创建符号链接? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$dest"
            echo -e "${GREEN}✓ 已删除旧文件: $dest${NC}"
        else
            echo -e "${YELLOW}⊘ 跳过: $dest${NC}"
            return 0
        fi
    fi

    # 确保目标目录存在
    local dest_dir
    dest_dir=$(dirname "$dest")
    mkdir -p "$dest_dir"

    # 创建符号链接
    ln -s "$src" "$dest"
    echo -e "${GREEN}✓ 已创建符号链接: $dest -> $src${NC}"
}

# 主配置文件
echo "========================================="
echo "链接主配置文件..."
echo "========================================="

create_symlink "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
create_symlink "$DOTFILES_DIR/.p10k.zsh" "$HOME/.p10k.zsh"
create_symlink "$DOTFILES_DIR/.vimrc" "$HOME/.vimrc"
create_symlink "$DOTFILES_DIR/.xinitrc" "$HOME/.xinitrc"
create_symlink "$DOTFILES_DIR/.Xresources" "$HOME/.Xresources"
create_symlink "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
create_symlink "$DOTFILES_DIR/.keynavrc" "$HOME/.keynavrc"
create_symlink "$DOTFILES_DIR/.wallpapers" "$HOME/.wallpapers"

# .config 目录下的配置（直接链接整个文件夹）
echo ""
echo "========================================="
echo "链接 .config 目录..."
echo "========================================="

create_symlink "$DOTFILES_DIR/.config/picom.conf" "$HOME/.config/picom.conf"
create_symlink "$DOTFILES_DIR/.config/alacritty" "$HOME/.config/alacritty"
create_symlink "$DOTFILES_DIR/.config/btop" "$HOME/.config/btop"
create_symlink "$DOTFILES_DIR/.config/cava" "$HOME/.config/cava"
create_symlink "$DOTFILES_DIR/.config/dunst" "$HOME/.config/dunst"
create_symlink "$DOTFILES_DIR/.config/fastfetch" "$HOME/.config/fastfetch"
create_symlink "$DOTFILES_DIR/.config/gtk-3.0" "$HOME/.config/gtk-3.0"
create_symlink "$DOTFILES_DIR/.config/i3" "$HOME/.config/i3"
create_symlink "$DOTFILES_DIR/.config/kitty" "$HOME/.config/kitty"
create_symlink "$DOTFILES_DIR/.config/matugen" "$HOME/.config/matugen"
create_symlink "$DOTFILES_DIR/.config/mpd" "$HOME/.config/mpd"
create_symlink "$DOTFILES_DIR/.config/ncmpcpp" "$HOME/.config/ncmpcpp"
create_symlink "$DOTFILES_DIR/.config/nvim" "$HOME/.config/nvim"
create_symlink "$DOTFILES_DIR/.config/polybar" "$HOME/.config/polybar"
create_symlink "$DOTFILES_DIR/.config/rofi" "$HOME/.config/rofi"
create_symlink "$DOTFILES_DIR/.config/yazi" "$HOME/.config/yazi"

# 脚本目录
echo ""
echo "========================================="
echo "链接脚本目录..."
echo "========================================="

create_symlink "$DOTFILES_DIR/.scripts" "$HOME/.scripts"

echo ""
echo "========================================="
echo -e "${GREEN}✓ 符号链接创建完成！${NC}"
echo "========================================="
echo ""
echo "提示："
echo "1. 如果某些应用需要重新加载配置，请重启对应应用"
echo "2. 对于 GTK 主题，可能需要重新登录或重启桌面环境"
echo "3. 使用 'ls -la' 命令可以验证符号链接是否创建成功"
