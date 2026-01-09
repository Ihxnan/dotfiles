#!/bin/bash

# 亮度图标（使用Font Awesome）
BRIGHTNESS_LOW=""
BRIGHTNESS_MID=""
BRIGHTNESS_HIGH=""
BRIGHTNESS_ERROR="⚠️"

# 获取亮度函数
get_brightness() {
    # 方案1: 使用brightnessctl（推荐）
    if command -v brightnessctl &> /dev/null; then
        current=$(brightnessctl get 2>/dev/null)
        max=$(brightnessctl max 2>/dev/null)
    # 方案2: 直接读取sys文件
    elif [ -d /sys/class/backlight/* ]; then
        backlight_path=$(find /sys/class/backlight/* -maxdepth 0 | head -n 1)
        current=$(cat "$backlight_path/brightness" 2>/dev/null)
        max=$(cat "$backlight_path/max_brightness" 2>/dev/null)
    # 方案3: xfpm-power-backlight-helper
    elif command -v xfpm-power-backlight-helper &> /dev/null; then
        current=$(xfpm-power-backlight-helper --get-brightness 2>/dev/null)
        max=96000
    else
        return 1
    fi

    # 计算百分比
    if [ -n "$current" ] && [ -n "$max" ] && [ "$max" -ne 0 ]; then
        echo $(( (current * 100 + max / 2) / max ))
        return 0
    fi
    return 1
}

# 执行亮度获取
BRIGHTNESS_LEVEL=$(get_brightness)

# 处理图标
if [ -z "$BRIGHTNESS_LEVEL" ] || ! [[ "$BRIGHTNESS_LEVEL" =~ ^[0-9]+$ ]] || [ "$BRIGHTNESS_LEVEL" -lt 0 ] || [ "$BRIGHTNESS_LEVEL" -gt 100 ]; then
    ICON="$BRIGHTNESS_ERROR"
    BRIGHTNESS_LEVEL="--"
elif [ "$BRIGHTNESS_LEVEL" -le 33 ]; then
    ICON="$BRIGHTNESS_LOW"
elif [ "$BRIGHTNESS_LEVEL" -ge 67 ]; then
    ICON="$BRIGHTNESS_HIGH"
else
    ICON="$BRIGHTNESS_MID"
fi

# 处理颜色
if [ "$ICON" = "$BRIGHTNESS_ERROR" ]; then
    COLOR="#FF9800"
elif [ "$BRIGHTNESS_LEVEL" -le 20 ]; then
    COLOR="#4A6FA5"
elif [ "$BRIGHTNESS_LEVEL" -le 40 ]; then
    COLOR="#5D9CEC"
elif [ "$BRIGHTNESS_LEVEL" -le 60 ]; then
    COLOR="#84B6F4"
elif [ "$BRIGHTNESS_LEVEL" -le 80 ]; then
    COLOR="#B3D1FF"
else
    COLOR="#E6EEFF"
fi

# 输出polybar格式
echo "%{F$COLOR}$ICON $BRIGHTNESS_LEVEL%%{F-}"
