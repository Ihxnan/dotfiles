#!/usr/bin/env bash

plugins_dir=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins

echo ">>> 克隆 Zsh 插件..."
git clone --depth=1 https://github.com/zsh-users/zsh-completions $plugins_dir/zsh-completions || true
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions $plugins_dir/zsh-autosuggestions || true
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git $plugins_dir/zsh-syntax-highlighting || true
git clone --depth=1 https://github.com/Aloxaf/fzf-tab $plugins_dir/fzf-tab || true

echo ">>> 安装 Powerlevel10k 主题..."
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k || true



