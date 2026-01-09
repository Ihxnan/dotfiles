#!/bin/bash

# 仅使用 amixer 的音量控制脚本
# 支持点击和滚轮事件

# 处理点击事件
handle_event() {
    local button=$1
    
    case $button in
        1)  # 左键点击 - 切换静音
            amixer set Master toggle &> /dev/null
            ;;
        4)  # 滚轮上滚 - 音量增加5%
            amixer set Master 3%+ &> /dev/null
            ;;
        5)  # 滚轮下滚 - 音量减少5%
            amixer set Master 3%- &> /dev/null
            ;;
    esac
}

# 如果有点击事件，则处理事件
if [ -n "$BLOCK_BUTTON" ]; then
    handle_event $BLOCK_BUTTON
fi

# 调用原有的音量信息显示脚本
~/.config/i3blocks/sound/sound_info.sh
