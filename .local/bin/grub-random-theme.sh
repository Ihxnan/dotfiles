#!/bin/bash

# 配置：你的主题根目录
THEME_DIR="/boot/grub/themes"
# GRUB 配置文件路径
GRUB_CONFIG="/etc/default/grub"

# 1. 获取所有有效主题目录（包含 theme.txt 的文件夹）
THEMES=()
for dir in "$THEME_DIR"/*/; do
    if [ -f "${dir}theme.txt" ]; then
        THEMES+=("$dir")
    fi
done

# 没有主题则退出
if [ ${#THEMES[@]} -eq 0 ]; then
    echo "未找到任何 GRUB 主题！"
    exit 1
fi

# 2. 随机选择一个主题
RAND_THEME=${THEMES[$RANDOM % ${#THEMES[@]}]}

# 3. 修改 GRUB 配置文件（替换 GRUB_THEME 行）
sed -i "s|^GRUB_THEME=.*|GRUB_THEME=\"${RAND_THEME%/}/theme.txt\"|" "$GRUB_CONFIG"

# 4. 生成新的 GRUB 引导配置
grub-mkconfig -o /boot/grub/grub.cfg
