#!/usr/bin/env bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;36m'
NC='\033[0m'

FAILED_PACKAGES=()
LOG_FILE="$HOME/install_ohmyzsh_failed.log"

log_failed() {
    local package="$1"
    local reason="$2"
    FAILED_PACKAGES+=("$package: $reason")
    echo -e "${RED}✗ Failed: $package - $reason${NC}"
}

git_clone() {
    local url="$1"
    local dest="$2"
    local name="${3:-$(basename "$dest")}"
    echo -e "${YELLOW}Cloning: $name${NC}"
    if ! git clone --depth=1 "$url" "$dest" 2>&1; then
        log_failed "$name" "git clone failed"
        return 1
    fi
    echo -e "${GREEN}✓ Cloned: $name${NC}"
    return 0
}

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Oh My Zsh Installation Script${NC}"
echo -e "${BLUE}=========================================${NC}"

if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}Error: Please do not run this script as root!${NC}"
    exit 1
fi

echo -e "${YELLOW}Checking GitHub connectivity...${NC}"
if ! curl --connect-timeout 5 -s https://github.com > /dev/null 2>&1; then
    echo -e "${RED}Error: Cannot reach GitHub. Please check your network and try again.${NC}"
    exit 1
fi
echo -e "${GREEN}GitHub is reachable${NC}"

echo ""
echo -e "${YELLOW}This will install:${NC}"
echo "  - Oh My Zsh"
echo "  - Powerlevel10k theme"
echo "  - zsh-autosuggestions"
echo "  - zsh-syntax-highlighting"
echo "  - zsh-completions"
echo "  - fzf-tab"
echo ""
read -p "Do you want to install Oh My Zsh? [y/N] " -r REPLY
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Installation cancelled.${NC}"
    exit 0
fi

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Step 1: Install Oh My Zsh${NC}"
echo -e "${BLUE}=========================================${NC}"
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

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Step 2: Install Powerlevel10k${NC}"
echo -e "${BLUE}=========================================${NC}"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
if [[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]]; then
    git_clone "https://github.com/romkatv/powerlevel10k.git" "$ZSH_CUSTOM/themes/powerlevel10k" "powerlevel10k"
else
    echo -e "${GREEN}Powerlevel10k already installed${NC}"
fi

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Step 3: Install Zsh Plugins${NC}"
echo -e "${BLUE}=========================================${NC}"

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
echo -e "${BLUE}Step 4: Set Default Shell${NC}"
echo -e "${BLUE}=========================================${NC}"
if [[ "$SHELL" != "/usr/bin/zsh" ]]; then
    echo -e "${YELLOW}Changing default shell to Zsh...${NC}"
    if chsh -s /usr/bin/zsh; then
        echo -e "${GREEN}Default shell changed to Zsh${NC}"
        echo -e "${YELLOW}Please log out and log back in to apply changes${NC}"
    else
        echo -e "${RED}Failed to change default shell. Try manually: chsh -s /usr/bin/zsh${NC}"
    fi
else
    echo -e "${GREEN}Default shell is already Zsh${NC}"
fi

echo ""
echo -e "${BLUE}=========================================${NC}"
echo -e "${GREEN}✓ Oh My Zsh installation completed!${NC}"
echo -e "${BLUE}=========================================${NC}"

if [[ ${#FAILED_PACKAGES[@]} -gt 0 ]]; then
    echo -e "${RED}=========================================${NC}"
    echo -e "${RED}✗ ${#FAILED_PACKAGES[@]} item(s) failed to install${NC}"
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

    echo -e "${YELLOW}Failed items:${NC}"
    for failed in "${FAILED_PACKAGES[@]}"; do
        echo -e "${RED}  - $failed${NC}"
    done
    echo ""
    echo -e "${YELLOW}Failed items list saved to: $LOG_FILE${NC}"
else
    echo -e "${GREEN}✓ All components installed successfully!${NC}"
fi

echo ""
echo -e "${GREEN}Tips:${NC}"
echo "1. Restart your terminal or log out and log back in"
echo "2. On first launch, Powerlevel10k configuration wizard will start automatically"
