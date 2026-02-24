#!/usr/bin/env bash

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Dotfiles directory: $DOTFILES_DIR"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Dotfiles Dependency Installation Script${NC}"
echo -e "${BLUE}=========================================${NC}"

if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}Error: Please do not run this script as root!${NC}"
    exit 1
fi

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Step 1: Update System${NC}"
echo -e "${BLUE}=========================================${NC}"
sudo pacman -Syu --noconfirm

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Step 2: Install Base Dependencies${NC}"
echo -e "${BLUE}=========================================${NC}"
echo -e "${YELLOW}Installing window manager and desktop environment...${NC}"
sudo pacman -S --noconfirm i3-wm i3-gaps polybar rofi dunst picom feh

echo -e "${YELLOW}Installing terminals...${NC}"
sudo pacman -S --noconfirm alacritty kitty

echo -e "${YELLOW}Installing music software...${NC}"
sudo pacman -S --noconfirm mpd ncmpcpp cava playerctl

echo -e "${YELLOW}Installing system tools...${NC}"
sudo pacman -S --noconfirm btop fastfetch nvidia-utils eza fzf

echo -e "${YELLOW}Installing editor...${NC}"
sudo pacman -S --noconfirm neovim

echo -e "${YELLOW}Installing screenshot tool...${NC}"
sudo pacman -S --noconfirm flameshot

echo -e "${YELLOW}Installing other tools...${NC}"
sudo pacman -S --noconfirm lolcat ipython

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Step 3: Install Shell and Plugins${NC}"
echo -e "${BLUE}=========================================${NC}"
echo -e "${YELLOW}Installing Zsh...${NC}"
sudo pacman -S --noconfirm zsh

echo -e "${YELLOW}Checking Oh My Zsh...${NC}"
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo -e "${YELLOW}Installing Oh My Zsh...${NC}"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo -e "${GREEN}Oh My Zsh already installed${NC}"
fi

echo -e "${YELLOW}Checking Powerlevel10k...${NC}"
if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]]; then
    echo -e "${YELLOW}Installing Powerlevel10k...${NC}"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
else
    echo -e "${GREEN}Powerlevel10k already installed${NC}"
fi

echo -e "${YELLOW}Installing Zsh plugins...${NC}"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
else
    echo -e "${GREEN}zsh-autosuggestions already installed${NC}"
fi

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
else
    echo -e "${GREEN}zsh-syntax-highlighting already installed${NC}"
fi

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-completions" ]]; then
    git clone https://github.com/zsh-users/zsh-completions $ZSH_CUSTOM/plugins/zsh-completions
else
    echo -e "${GREEN}zsh-completions already installed${NC}"
fi

if [[ ! -d "$ZSH_CUSTOM/plugins/fzf-tab" ]]; then
    git clone https://github.com/Aloxaf/fzf-tab $ZSH_CUSTOM/plugins/fzf-tab
else
    echo -e "${GREEN}fzf-tab already installed${NC}"
fi

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Step 4: Install AUR Packages${NC}"
echo -e "${BLUE}=========================================${NC}"
echo -e "${YELLOW}Installing matugen...${NC}"
paru -S --noconfirm matugen

echo -e "${YELLOW}Installing yazi...${NC}"
paru -S --noconfirm yazi

echo -e "${YELLOW}Installing lazygit...${NC}"
paru -S --noconfirm lazygit

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Step 5: Install Other Dependencies${NC}"
echo -e "${BLUE}=========================================${NC}"
echo -e "${YELLOW}Installing Neovim dependencies...${NC}"
sudo pacman -S --noconfirm npm python-pip tree-sitter-cli bat

echo -e "${YELLOW}Installing lock screen tool...${NC}"
paru -S --noconfirm i3lock-color

echo -e "${YELLOW}Installing SSH file system...${NC}"
sudo pacman -S --noconfirm sshfs

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Step 6: Create Required Directories${NC}"
echo -e "${BLUE}=========================================${NC}"
mkdir -p ~/Pictures/Screenshots
mkdir -p ~/.local/share/fcitx5/themes/Matugen
echo -e "${GREEN}Directories created${NC}"

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Step 7: Set Default Shell${NC}"
echo -e "${BLUE}=========================================${NC}"
if [[ "$SHELL" != "/bin/zsh" ]]; then
    echo -e "${YELLOW}Changing default shell to Zsh...${NC}"
    chsh -s /bin/zsh
    echo -e "${GREEN}Default shell changed to Zsh${NC}"
    echo -e "${YELLOW}Please log out and log back in to apply changes${NC}"
else
    echo -e "${GREEN}Default shell is already Zsh${NC}"
fi

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Step 8: Execute symlink.sh${NC}"
echo -e "${BLUE}=========================================${NC}"
if [[ -f "$DOTFILES_DIR/symlink.sh" ]]; then
    echo -e "${YELLOW}Executing symlink.sh...${NC}"
    bash "$DOTFILES_DIR/symlink.sh"
else
    echo -e "${RED}Error: symlink.sh not found!${NC}"
    exit 1
fi

echo -e "${BLUE}=========================================${NC}"
echo -e "${GREEN}✓ All dependencies installed!${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""
echo -e "${GREEN}Tips:${NC}"
echo "1. Please log out and log back in to apply Zsh configuration"
echo "2. Run 'nvim' to open Neovim, plugins will be installed automatically"
echo ""
echo -e "${YELLOW}Note:${NC}"
echo "- If you encounter Conda initialization errors, you can remove Conda-related code from .zshrc"
