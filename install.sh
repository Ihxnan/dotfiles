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

ask_section() {
    local description="$1"
    local step="$2"
    echo ""
    echo -ne "${YELLOW}Install $step: ${description}? [Y/n] ${NC}"
    read -r response
    case "$response" in
        [nN][oO]|[nN]) return 1 ;;
        *) return 0 ;;
    esac
}

install_pacman() {
    local packages=("$@")
    echo -e "${YELLOW}Installing: ${packages[*]}${NC}"
    if ! sudo pacman -S --needed --noconfirm "${packages[@]}" 2>&1; then
        log_failed "${packages[*]}" "pacman installation failed"
        return 1
    fi
    echo -e "${GREEN}✓ Installed: ${packages[*]}${NC}"
    return 0
}

install_paru() {
    local package="$1"
    echo -e "${YELLOW}Installing: $package${NC}"
    if ! paru -S --needed --noconfirm "$package" 2>&1; then
        log_failed "$package" "paru installation failed"
        return 1
    fi
    echo -e "${GREEN}✓ Installed: $package${NC}"
    return 0
}

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Dotfiles Dependency Installation Script${NC}"
echo -e "${BLUE}=========================================${NC}"

if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}Error: Please do not run this script as root!${NC}"
    exit 1
fi

if ! command -v paru >/dev/null 2>&1; then
    echo -e "${RED}Error: paru is not installed. Please install paru first (e.g. from AUR).${NC}"
    exit 1
fi

if ask_section "pacman -Syu (full system upgrade)" "Step 1"; then
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Step 1: Update System${NC}"
echo -e "${BLUE}=========================================${NC}"
echo -e "${YELLOW}Updating system...${NC}"
if ! sudo pacman -Syu --noconfirm 2>&1; then
    log_failed "system update" "pacman update failed"
fi
else
    echo -e "${YELLOW}Skipping system update${NC}"
fi

if ask_section "fonts, xorg, i3, terminal, audio, utils, neovim, etc." "Step 2"; then
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Step 2: Install Base Dependencies${NC}"
echo -e "${BLUE}=========================================${NC}"

install_pacman noto-fonts noto-fonts-emoji noto-fonts-cjk ttf-jetbrains-mono ttf-jetbrains-mono-nerd

install_pacman xorg xorg-xinit mesa xf86-video-intel lightdm lightdm-gtk-greeter i3-wm polybar rofi dunst picom feh
sudo systemctl set-default multi-user.target

install_pacman alacritty kitty

install_pacman mpd ncmpcpp cava playerctl pipewire-pulse
if [[ $? -eq 0 ]]; then
    systemctl --user enable --now pipewire-pulse
fi

install_pacman btop eza fzf

install_pacman neovim

install_pacman flameshot

install_pacman lolcat ipython zsh
else
    echo -e "${YELLOW}Skipping base dependencies${NC}"
fi

if ask_section "matugen, yazi, lazygit, jq, jdtls, xclip, miniconda3" "Step 3"; then
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Step 3: Install AUR Packages${NC}"
echo -e "${BLUE}=========================================${NC}"
install_paru matugen

install_paru yazi

install_paru lazygit

install_paru jq

install_paru jdtls

install_paru xclip

if install_paru miniconda3; then
    /opt/miniconda3/bin/conda config --set auto_activate_base false
fi
else
    echo -e "${YELLOW}Skipping AUR packages${NC}"
fi

if ask_section "nodejs, python, i3lock-color, sshfs, xdg-desktop-portal, chromium" "Step 4"; then
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Step 4: Install Other Dependencies${NC}"
echo -e "${BLUE}=========================================${NC}"
install_pacman nodejs npm python tree-sitter-cli bat

install_paru i3lock-color

install_pacman sshfs

install_paru xdg-desktop-portal-termfilechooser-hunkyburrito-git

install_paru chromium
else
    echo -e "${YELLOW}Skipping other dependencies${NC}"
fi

if ask_section "create ~/WorkSpace, ~/.mpd, ~/Music, ~/Pictures/Screenshots, etc." "Step 5"; then
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Step 5: Create Required Directories${NC}"
echo -e "${BLUE}=========================================${NC}"
mkdir -p ~/WorkSpace/Algorithm/cpp
mkdir -p ~/WorkSpace/Algorithm/python
mkdir -p ~/.mpd/playlists
mkdir -p ~/Music
sudo mkdir -p /etc/timidity
sudo touch /etc/timidity/timidity.cfg
mkdir -p ~/Pictures/Screenshots
mkdir -p ~/.local/share/fcitx5/themes/Matugen
echo -e "${GREEN}Directories created${NC}"
else
    echo -e "${YELLOW}Skipping directory creation${NC}"
fi

if ask_section "LightDM autologin configuration" "Step 5.5"; then
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Step 5.5: Configure LightDM Autologin${NC}"
echo -e "${BLUE}=========================================${NC}"
sudo mkdir -p /etc/lightdm/lightdm.conf.d
sudo tee /etc/lightdm/lightdm.conf.d/50-autologin.conf > /dev/null <<EOF
[Seat:*]
autologin-user=$USER
autologin-user-timeout=0
autologin-session=i3
EOF
sudo groupadd -r autologin 2>/dev/null
sudo gpasswd -a "$USER" autologin
echo -e "${GREEN}LightDM autologin configured for $USER${NC}"
else
    echo -e "${YELLOW}Skipping LightDM autologin${NC}"
fi

if ask_section "run symlink.sh to create config symlinks" "Step 6"; then
echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Step 6: Execute symlink.sh${NC}"
echo -e "${BLUE}=========================================${NC}"
if [[ -f "$DOTFILES_DIR/symlink.sh" ]]; then
    echo -e "${YELLOW}Executing symlink.sh...${NC}"
    bash "$DOTFILES_DIR/symlink.sh"
else
    echo -e "${RED}Error: symlink.sh not found!${NC}"
    exit 1
fi
else
    echo -e "${YELLOW}Skipping symlink.sh${NC}"
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
echo "1. Run 'bash install-ohmyzsh.sh' to install Oh My Zsh (requires GitHub access)"
echo "2. Run 'nvim' to open Neovim, plugins will be installed automatically"
echo ""
echo -e "${YELLOW}Note:${NC}"
echo "- If you encounter Conda initialization errors, you can remove Conda-related code from .zshrc"
