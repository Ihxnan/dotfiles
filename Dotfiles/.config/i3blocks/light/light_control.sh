#!/bin/bash

# 使用 xfpm-power-backlight-helper 的亮度控制脚本（支持亮度为0）
# 支持点击和滚轮事件，通过 pkexec 获取 root 权限

# 获取当前亮度值（需要权限）
get_current_brightness() {
    pkexec xfpm-power-backlight-helper --get-brightness | awk '{print $1}'
}

# 处理点击事件（所有调整操作通过 pkexec 执行）
handle_event() {
    local button=$1
    local current=$(get_current_brightness)
    local max=96000  # 固定最大亮度值
    local step=$(( max / 20 ))  # 5% 步长（4800）
    
    # 确保步长至少为1
    if [ $step -lt 1 ]; then
        step=1
    fi

    case $button in
        1)  # 左键点击 - 切换至50%亮度（48000）
            pkexec xfpm-power-backlight-helper --set-brightness $(( max * 2 / 5 )) &> /dev/null
            ;;
        4)  # 滚轮上滚 - 亮度增加5%
            local new_brightness=$(( current + step ))
            if [ $new_brightness -gt $max ]; then
                new_brightness=$max
            fi
            pkexec xfpm-power-backlight-helper --set-brightness $new_brightness &> /dev/null
            ;;
        5)  # 滚轮下滚 - 亮度减少5%（允许降至0）
            local new_brightness=$(( current - step ))
            # 限制最小亮度为0（全黑）
            if [ $new_brightness -lt 0 ]; then
                new_brightness=0
            fi
            pkexec xfpm-power-backlight-helper --set-brightness $new_brightness &> /dev/null
            ;;
    esac
}

# 处理点击/滚轮事件
if [ -n "$BLOCK_BUTTON" ]; then
    handle_event $BLOCK_BUTTON
fi

# 调用亮度信息显示脚本
~/.config/i3blocks/light/brightness.sh
