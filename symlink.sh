#!/usr/bin/env bash

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Dotfiles directory: $DOTFILES_DIR"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

create_symlink() {
    local src="$1"
    local dest="$2"

    if [[ ! -e "$src" ]]; then
        echo -e "${RED}✗ Source file not found: $src${NC}"
        return 1
    fi

    if [[ -e "$dest" || -L "$dest" ]]; then
        echo -e "${YELLOW}⚠ Target already exists: $dest${NC}"
        read -p "Delete and create symlink? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$dest"
            echo -e "${GREEN}✓ Removed old file: $dest${NC}"
        else
            echo -e "${YELLOW}⊘ Skipped: $dest${NC}"
            return 0
        fi
    fi

    local dest_dir
    dest_dir=$(dirname "$dest")
    mkdir -p "$dest_dir"

    ln -s "$src" "$dest"
    echo -e "${GREEN}✓ Created symlink: $dest -> $src${NC}"
}

echo "========================================="
echo "Linking main config files..."
echo "========================================="

create_symlink "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
create_symlink "$DOTFILES_DIR/.p10k.zsh" "$HOME/.p10k.zsh"
create_symlink "$DOTFILES_DIR/.vimrc" "$HOME/.vimrc"
create_symlink "$DOTFILES_DIR/.xinitrc" "$HOME/.xinitrc"
create_symlink "$DOTFILES_DIR/.Xresources" "$HOME/.Xresources"
create_symlink "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
create_symlink "$DOTFILES_DIR/.keynavrc" "$HOME/.keynavrc"
create_symlink "$DOTFILES_DIR/.wallpapers" "$HOME/.wallpapers"

echo ""
echo "========================================="
echo "Linking .config directory..."
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

echo ""
echo "========================================="
echo "Linking scripts directory..."
echo "========================================="

create_symlink "$DOTFILES_DIR/.scripts" "$HOME/.scripts"

echo ""
echo "========================================="
echo -e "${GREEN}✓ Symlink creation completed!${NC}"
echo "========================================="
echo ""
echo "Tips:"
echo "1. If some apps need to reload config, restart the corresponding app"
echo "2. For GTK themes, you may need to re-login or restart the desktop environment"
echo "3. Use 'ls -la' command to verify if symlinks are created successfully"
