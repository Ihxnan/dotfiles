#!/bin/bash

# 核心配置：MPD 服务地址
MPD_HOST="localhost"
MPD_PORT="6600"
COLOR_FILE="/tmp/mpd_current_color"
mkdir -p /tmp && touch "$COLOR_FILE" && chmod 644 "$COLOR_FILE"

# 检查 mpc 是否安装
if ! command -v mpc &> /dev/null; then
    # 如果 mpc 未安装，也静默退出（或根据需要显示错误）
    exit 0
fi

##############################################################################
# --- 核心修改：MPD 未启动时静默退出 ---
# 如果 MPD 服务未响应，脚本直接退出，不输出任何内容到状态栏。
##############################################################################
if ! mpc -h "$MPD_HOST" -p "$MPD_PORT" status &> /dev/null; then
    exit 0  # MPD 未启动，静默退出
fi
##############################################################################


# 处理鼠标点击事件
case $BLOCK_BUTTON in
    2) mpc -h "$MPD_HOST" -p "$MPD_PORT" toggle ;;  # 中键：播放/暂停
    3) mpc -h "$MPD_HOST" -p "$MPD_PORT" next ;;    # 右键：下一首
    1) mpc -h "$MPD_HOST" -p "$MPD_PORT" prev ;;    # 左键：上一首
esac

# 提取 MPD 播放状态
status=$(mpc -h "$MPD_HOST" -p "$MPD_PORT" status | 
         awk '/\[(playing|paused|stopped)\]/ {
             gsub(/\[|\]/, "", $1);
             print $1; 
             exit
         }')
status=${status:-"stopped"}

# 获取歌曲信息
if [[ "$status" == "playing" || "$status" == "paused" ]]; then
    artist=$(mpc -h "$MPD_HOST" -p "$MPD_PORT" current -f "%artist%" 2>/dev/null || echo "未知艺术家")
    title=$(mpc -h "$MPD_HOST" -p "$MPD_PORT" current -f "%title%" 2>/dev/null || echo "未知标题")
else
    artist="未播放"
    title="音乐"
fi

# 设置状态图标
case "$status" in
    "playing") icon="⏸" ;;
    "paused")  icon="▶" ;;
    "stopped") icon="⏹" ;;
esac

# 颜色配置
colors=(
    "#E53935"  # 红色
    "#EC407A"  # 粉红色
    "#9C27B0"  # 紫色
    "#3949AB"  # 靛蓝色
    "#1E88E5"  # 蓝色
    "#00ACC1"  # 青色
    "#43A047"  # 绿色
)

if [ "$status" = "playing" ]; then
    RANDOM_SEED=$(date +%N)
    index=$(( RANDOM_SEED % ${#colors[@]} ))
    COLOR=${colors[$index]}
    echo "$COLOR" > "$COLOR_FILE"
elif [ "$status" = "paused" ]; then
    COLOR="#FFFFFF"
else
    COLOR="#9E9E9E"
fi

# 中文字符处理
artist_utf8=$(echo "$artist" | iconv -f UTF-8 -t UTF-8//IGNORE 2>/dev/null)
title_utf8=$(echo "$title" | iconv -f UTF-8 -t UTF-8//IGNORE 2>/dev/null)

# 截取长度
artist_display=$(echo "$artist_utf8" | awk '{
    if (length($0) > 30) print substr($0, 1, 30)"..."; 
    else print $0;
}')
title_display=$(echo "$title_utf8" | awk '{
    if (length($0) > 40) print substr($0, 1, 40)"..."; 
    else print $0;
}')

# 最终输出
echo "$icon $artist_display - $title_display"
echo "MPD状态: $(echo $status | tr '[:lower:]' '[:upper:]') | 左键上一首 中键暂停 右键下一首"
echo "$COLOR"
