#!/usr/bin/env bash

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Dotfiles directory: $DOTFILES_DIR"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;36m'
NC='\033[0m'

FAILED_PACKAGES=()
LOG_FILE="$DOTFILES_DIR/install_failed.log"

log_failed() {
    local package="$1"
    local reason="$2"
    FAILED_PACKAGES+=("$package: $reason")
    echo -e "${RED}✗ Failed: $package - $reason${NC}"
}

install_pacman() {
    local packages="$*"
    echo -e "${YELLOW}Installing: $packages${NC}"
    if ! sudo pacman -S --noconfirm $packages 2>&1; then
        log_failed "$packages" "pacman installation failed"
        return 1
    fi
    echo -e "${GREEN}✓ Installed: $packages${NC}"
    return 0
}

install_paru() {
    local package="$1"
    echo -e "${YELLOW}Installing: $package${NC}"
    if ! paru -S --noconfirm $package 2>&1; then
        log_failed "$package" "paru installation failed"
        return 1
    fi
    echo -e "${GREEN}✓ Installed: $package${NC}"
    return 0
}

git_clone() {
    local url="$1"
    local dest="$2"
    local name="${3:-$(basename $dest)}"
    echo -e "${YELLOW}Cloning: $name${NC}"
    if ! git clone --depth=1 $url $dest 2>&1; then
        log_failed "$name" "git clone failed"
        return 1
    fi
    echo -e "${GREEN}✓ Cloned: $name${NC}"
    return 0
}

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
echo -e "${YELLOW}Updating system...${NC}"
if ! sudo pacman -Syu --noconfirm 2>&1; then
    log_failed "system update" "pacman update failed"
fi

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Step 2: Install Base Dependencies${NC}"
echo -e "${BLUE}=========================================${NC}"

install_pacman noto-fonts noto-fonts-emoji noto-fonts-cjk ttf-jetbrains-mono ttf-jetbrains-mono-nerd

install_pacman xorg xorg-xinit mesa xf86-video-intel lightdm lightdm-gtk-greeter i3-wm i3-gaps polybar rofi dunst picom feh
if [[ $? -eq 0 ]]; then
    sudo systemctl enable lightdm
    sudo systemctl set-default graphical.target
fi

install_pacman alacritty kitty

install_pacman mpd ncmpcpp cava playerctl pipewire-pulse
if [[ $? -eq 0 ]]; then
    systemctl --user enable --now pipewire-pulse
fi

install_pacman btop eza fzf

install_pacman neovim

install_pacman flameshot

install_pacman lolcat ipython

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Step 3: Install Shell and Plugins${NC}"
echo -e "${BLUE}=========================================${NC}"
install_pacman zsh

echo -e "${YELLOW}Checking Oh My Zsh...${NC}"
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo -e "${YELLOW}Installing Oh My Zsh...${NC}"
    if ! sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended 2>&1; then
        log_failed "oh-my-zsh" "curl or install script failed"
    else
        echo -e "${GREEN}✓ Installed: oh-my-zsh${NC}"
    fi
else
    echo -e "${GREEN}Oh My Zsh already installed${NC}"
fi

echo -e "${YELLOW}Checking Powerlevel10k...${NC}"
if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]]; then
    git_clone "https://github.com/romkatv/powerlevel10k.git" "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" "powerlevel10k"
else
    echo -e "${GREEN}Powerlevel10k already installed${NC}"
fi

echo -e "${YELLOW}Installing Zsh plugins...${NC}"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
    git_clone "https://github.com/zsh-users/zsh-autosuggestions" "$ZSH_CUSTOM/plugins/zsh-autosuggestions" "zsh-autosuggestions"
else
    echo -e "${GREEN}zsh-autosuggestions already installed${NC}"
fi

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
    git_clone "https://github.com/zsh-users/zsh-syntax-highlighting.git" "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" "zsh-syntax-highlighting"
else
    echo -e "${GREEN}zsh-syntax-highlighting already installed${NC}"
fi

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-completions" ]]; then
    git_clone "https://github.com/zsh-users/zsh-completions" "$ZSH_CUSTOM/plugins/zsh-completions" "zsh-completions"
else
    echo -e "${GREEN}zsh-completions already installed${NC}"
fi

if [[ ! -d "$ZSH_CUSTOM/plugins/fzf-tab" ]]; then
    git_clone "https://github.com/Aloxaf/fzf-tab" "$ZSH_CUSTOM/plugins/fzf-tab" "fzf-tab"
else
    echo -e "${GREEN}fzf-tab already installed${NC}"
fi

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Step 4: Install AUR Packages${NC}"
echo -e "${BLUE}=========================================${NC}"
install_paru matugen

install_paru yazi

install_paru lazygit

install_paru jq

install_paru jdtls

install_paru xclip

if install_paru miniconda3; then
    zsh -c "conda config --set auto_activate_base false"
fi

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Step 5: Install Other Dependencies${NC}"
echo -e "${BLUE}=========================================${NC}"
install_pacman npm python tree-sitter-cli bat

install_paru i3lock-color

install_pacman sshfs

install_paru xdg-desktop-portal-termfilechooser-hunkyburrito-git

install_paru chromium

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Step 6: Create Required Directories${NC}"
echo -e "${BLUE}=========================================${NC}"
mkdir -p ~/WorkSpace/Algorithm/cpp
mkdir -p ~/WorkSpace/Algorithm/python
mkdir -p ~/.mpd/playlists
mkdir ~/Music
sudo mkdir /etc/timidity
sudo touch /etc/timidity/timidity.cfg
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
echo -e "${GREEN}✓ Installation script completed!${NC}"
echo -e "${BLUE}=========================================${NC}"

if [[ ${#FAILED_PACKAGES[@]} -gt 0 ]]; then
    echo -e "${RED}=========================================${NC}"
    echo -e "${RED}✗ ${#FAILED_PACKAGES[@]} package(s) failed to install${NC}"
    echo -e "${RED}=========================================${NC}"

    {
        echo "Failed Installation Log - $(date)"
        echo "========================================"
        echo ""
        for failed in "${FAILED_PACKAGES[@]}"; do
            echo "- $failed"
        done
        echo ""
        echo "========================================"
        echo "Total failed: ${#FAILED_PACKAGES[@]}"
    } >"$LOG_FILE"

    echo -e "${YELLOW}Failed packages:${NC}"
    for failed in "${FAILED_PACKAGES[@]}"; do
        echo -e "${RED}  - $failed${NC}"
    done
    echo ""
    echo -e "${YELLOW}Failed packages list saved to: $LOG_FILE${NC}"
    echo -e "${YELLOW}You can retry installing them manually later.${NC}"
else
    echo -e "${GREEN}✓ All packages installed successfully!${NC}"
fi

echo ""
echo -e "${GREEN}Tips:${NC}"
echo "1. Please log out and log back in to apply Zsh configuration"
echo "2. Run 'nvim' to open Neovim, plugins will be installed automatically"
echo ""
echo -e "${YELLOW}Note:${NC}"
echo "- If you encounter Conda initialization errors, you can remove Conda-related code from .zshrc"
