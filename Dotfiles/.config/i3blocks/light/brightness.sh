#!/bin/sh

# 亮度图标定义
# BRIGHTNESS_LOW="🌕"
# BRIGHTNESS_MID="🌒"
# BRIGHTNESS_HIGH="🌑"
# BRIGHTNESS_ERROR="⚠️"

BRIGHTNESS_LOW=" "
BRIGHTNESS_MID=" "
BRIGHTNESS_HIGH=" "
BRIGHTNESS_ERROR="⚠️"

# 使用xfpm-power-backlight-helper获取亮度信息
get_brightness() {
    # 检查xfpm-power-backlight-helper是否存在
    if ! command -v xfpm-power-backlight-helper &> /dev/null; then
        return 1
    fi

    # 获取当前亮度和最大亮度
    local current=$(xfpm-power-backlight-helper --get-brightness 2>/dev/null)
    local max=96000

    # 验证获取到的值
    if [ -n "$current" ] && [ -n "$max" ] && [ "$max" -ne 0 ]; then
        # 计算百分比并四舍五入
        echo "$(( (current * 100 + max / 2) / max ))"
        return 0
    fi

    # 获取失败
    return 1
}

# 获取亮度级别
BRIGHTNESS_LEVEL=$(get_brightness)

# 确定显示的图标
if [ -z "$BRIGHTNESS_LEVEL" ] || [ "$BRIGHTNESS_LEVEL" -lt 0 ] || [ "$BRIGHTNESS_LEVEL" -gt 100 ]; then
    ICON="$BRIGHTNESS_ERROR"
    BRIGHTNESS_LEVEL="--"
elif [ "$BRIGHTNESS_LEVEL" -le 33 ]; then
    ICON="$BRIGHTNESS_LOW"
elif [ "$BRIGHTNESS_LEVEL" -ge 67 ]; then
    ICON="$BRIGHTNESS_HIGH"
else
    ICON="$BRIGHTNESS_MID"
fi

# 格式化输出
echo "$ICON" "$BRIGHTNESS_LEVEL" | awk '{ printf(" %s%3s%% \n", $1, $2) }'

echo "BRI: $BRIGHTNESS_LEVEL%"

# 多级渐变颜色设置（从低到高：深蓝→天蓝→浅蓝→淡青→亮青）
if [ "$ICON" = "$BRIGHTNESS_ERROR" ]; then
    # 错误状态 - 橙色（比红色更柔和但依然醒目）
    echo "#FF9800"
elif [ "$BRIGHTNESS_LEVEL" -le 20 ]; then
    # 极低亮度 - 钴蓝色（明亮的深蓝色）
    echo "#4A6FA5"
elif [ "$BRIGHTNESS_LEVEL" -le 40 ]; then
    # 低亮度 - 湖蓝色
    echo "#5D9CEC"
elif [ "$BRIGHTNESS_LEVEL" -le 60 ]; then
    # 中等亮度 - 浅蓝色
    echo "#84B6F4"
elif [ "$BRIGHTNESS_LEVEL" -le 80 ]; then
    # 高亮度 - 淡蓝色
    echo "#B3D1FF"
else
    # 极高亮度 - 亮蓝白色
    echo "#E6EEFF"
fi
