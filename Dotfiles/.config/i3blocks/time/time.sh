#!/bin/sh

# 检查是否点击了鼠标左键（BLOCK_BUTTON=1），如果是则打开 gsimplecal
if [ "$BLOCK_BUTTON" = "1" ]; then
    i3-msg -q exec gsimplecal > /dev/null 2>&1
fi

# 输出格式化的时间（带时钟图标和时分秒）
date +" %H:%M:%S"
