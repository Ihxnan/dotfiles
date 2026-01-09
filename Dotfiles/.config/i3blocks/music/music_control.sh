#!/bin/bash

# 明确指定使用 Spotify 播放器
PLAYER="spotify"
# 临时文件用于保存当前播放时的颜色
COLOR_FILE="/tmp/spotify_current_color"

# 处理点击事件（针对 Spotify）
case $BLOCK_BUTTON in
    2) playerctl -p "$PLAYER" play-pause ;;  # 中键：播放/暂停
    3) playerctl -p "$PLAYER" next ;;        # 右键：下一首
    1) playerctl -p "$PLAYER" previous ;;    # 左键：上一首
esac

# 获取 Spotify 播放状态和信息
status=$(playerctl -p "$PLAYER" status 2>/dev/null)
artist=$(playerctl -p "$PLAYER" metadata artist 2>/dev/null)
title=$(playerctl -p "$PLAYER" metadata title 2>/dev/null)

# 显示内容格式化
if [ "$status" = "Playing" ]; then
    icon="⏸"
elif [ "$status" = "Paused" ]; then
    icon="▶"
else
    # echo "🎵 未播放音乐"
    # echo "🎵 未播放音乐"
    # 错误状态颜色
    # echo "#FF9800"
    # 清除颜色缓存
    # rm -f "$COLOR_FILE"
    exit 0
fi

# 定义颜色数组
colors=(
    "#E53935"  # 红色
    "#EC407A"  # 粉红色
    "#9C27B0"  # 紫色
    "#3949AB"  # 靛蓝色
    "#1E88E5"  # 蓝色
    "#00ACC1"  # 青色
    "#43A047"  # 绿色
)

# 确定颜色 - 播放时随机颜色，暂停时固定白色
if [ "$status" = "Playing" ]; then
    # 播放状态：生成新的随机颜色
    RANDOM_SEED=$(date +%N)
    index=$(( RANDOM_SEED % ${#colors[@]} ))
    COLOR=${colors[$index]}
    # 保存颜色到临时文件（用于切换回播放状态时参考）
    echo "$COLOR" > "$COLOR_FILE"
else
    # 暂停状态：固定使用白色
    COLOR="#FFFFFF"
fi

# 处理中文字符显示 - 使用更安全的方法截取字符串
# 使用 iconv 处理字符编码，确保正确显示中文
if [ -n "$artist" ] && [ -n "$title" ]; then
    # 将文本转换为UTF-8确保编码正确
    artist_utf8=$(echo "$artist" | iconv -f UTF-8 -t UTF-8//IGNORE)
    title_utf8=$(echo "$title" | iconv -f UTF-8 -t UTF-8//IGNORE)
    
    # 使用更安全的方法限制显示长度
    artist_display=$(echo "$artist_utf8" | awk '{ if (length($0) > 30) print substr($0, 1, 30)"..."; else print; }')
    title_display=$(echo "$title_utf8" | awk '{ if (length($0) > 40) print substr($0, 1, 40)"..."; else print; }')
else
    artist_display="未知艺术家"
    title_display="未知标题"
fi

# 主显示内容（状态栏）
echo "$icon $artist_display - $title_display"
# 次要显示内容（悬停提示）
echo "点击控制 Spotify | $status"
# 输出颜色值
echo "$COLOR"
