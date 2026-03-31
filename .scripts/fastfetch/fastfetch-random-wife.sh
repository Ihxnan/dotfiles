#!/bin/bash
# 脚本功能：
# 从随机老婆图片生成 API 下载图片并使用 Fastfetch 展示。
# 特性：支持 NSFW 模式，支持自动补货，支持已使用图片归档与自动清理，支持终端关闭后继续后台补货，图片强制转换为JPG格式。
# 优化：只下载 竖长型图片 (高度 > 宽度) + 无限重试下载

# ================= 配置区域 =================

# [开关] 强力清理 Fastfetch 内部缓存
# true  = 每次运行后清理 ~/.cache/fastfetch/images/ (防止转码缓存膨胀)
# false = 保留 Fastfetch 内部缓存
CLEAN_CACHE_MODE=true

# 每次补货下载多少张
DOWNLOAD_BATCH_SIZE=1000
# 最大库存上限 (待展示区)
MAX_CACHE_LIMIT=1000
# 库存少于多少张时开始补货
MIN_TRIGGER_LIMIT=600

# used 目录最大存放数量
# 超过此数量将按照时间顺序删除最旧的文件
MAX_USED_LIMIT=5000

# 最小有效图片尺寸（宽/高至少一个大于此值，单位px）
MIN_IMAGE_DIMENSION=300

# 🔥 核心：只保留竖图（高度 > 宽度）
ENABLE_PORTRAIT_ONLY=true

# ===========================================

# --- 0. 依赖检查 ---
check_dependencies() {
    local required_cmds=("curl" "jq" "file")
    local img_cmd=""
    
    if command -v magick >/dev/null 2>&1; then
        img_cmd="magick"
    elif command -v convert >/dev/null 2>&1; then
        img_cmd="convert"
    else
        echo "错误：缺少 ImageMagick 工具（magick/convert），请先安装！"
        exit 1
    fi

    for cmd in "${required_cmds[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo "错误：缺少必要工具 $cmd，请先安装！"
            exit 1
        fi
    done

    export IMG_CONVERT_CMD="$img_cmd"
}
check_dependencies

# --- 1. 参数解析 ---
NSFW_MODE=false
if [ "$NSFW" = "1" ]; then
    NSFW_MODE=true
fi

ARGS_FOR_FASTFETCH=()
for arg in "$@"; do
    if [ "$arg" == "--nsfw" ]; then
        NSFW_MODE=true
    else
        ARGS_FOR_FASTFETCH+=("$arg")
    fi
done

# --- 2. 目录配置 ---
if [ "$NSFW_MODE" = true ]; then
    CACHE_DIR="$HOME/.cache/fastfetch_waifu_nsfw"
    LOCK_FILE="/tmp/fastfetch_waifu_nsfw.lock"
else
    CACHE_DIR="$HOME/.cache/fastfetch_waifu"
    LOCK_FILE="/tmp/fastfetch_waifu.lock"
fi
USED_DIR="$CACHE_DIR/used"
mkdir -p "$CACHE_DIR" "$USED_DIR"

# --- 3. 核心函数 ---
check_network() {
    curl -s --connect-timeout 2 "https://1.1.1.1" >/dev/null 2>&1
    return $?
}

get_random_url() {
    local TIMEOUT="--connect-timeout 5 --max-time 15"
    RAND=$(((RANDOM % 3) + 1))

    if [ "$NSFW_MODE" = true ]; then
        case $RAND in
        1) curl -s $TIMEOUT "https://api.waifu.im/search?included_tags=waifu&is_nsfw=true" | jq -r '.images[0].url' ;;
        2) curl -s $TIMEOUT "https://api.waifu.pics/nsfw/waifu" | jq -r '.url' ;;
        3) curl -s $TIMEOUT "https://api.waifu.pics/nsfw/neko" | jq -r '.url' ;;
        esac
    else
        case $RAND in
        1) curl -s $TIMEOUT "https://api.waifu.im/search?included_tags=waifu&is_nsfw=false" | jq -r '.images[0].url' ;;
        2) curl -s $TIMEOUT "https://nekos.best/api/v2/waifu" | jq -r '.results[0].url' ;;
        3) curl -s $TIMEOUT "https://api.waifu.pics/sfw/waifu" | jq -r '.url' ;;
        esac
    fi
}

# 图片验证（竖图筛选）
is_valid_image() {
    local input_file="$1"
    if [ ! -s "$input_file" ]; then return 1; fi
    local file_type=$(file -b --mime-type "$input_file")
    if [[ ! "$file_type" =~ ^image/ ]]; then return 1; fi

    local width height
    if [ "$IMG_CONVERT_CMD" = "magick" ]; then
        width=$($IMG_CONVERT_CMD identify -format "%w" "$input_file" 2>/dev/null)
        height=$($IMG_CONVERT_CMD identify -format "%h" "$input_file" 2>/dev/null)
    else
        width=$(identify -format "%w" "$input_file" 2>/dev/null)
        height=$(identify -format "%h" "$input_file" 2>/dev/null)
    fi

    if [ -z "$width" ] || [ -z "$height" ] || [ "$width" -le "$MIN_IMAGE_DIMENSION" ] || [ "$height" -le "$MIN_IMAGE_DIMENSION" ]; then
        return 1
    fi

    if [ "$ENABLE_PORTRAIT_ONLY" = true ] && [ "$height" -le "$width" ]; then
        return 1
    fi
    
    return 0
}

convert_to_jpg() {
    local input_file="$1"
    local output_file="$2"
    $IMG_CONVERT_CMD "$input_file" -quality 95 -strip "$output_file" >/dev/null 2>&1
    if [ $? -eq 0 ] && is_valid_image "$output_file"; then return 0; else return 1; fi
}

# 🔥 无限重试下载，直到成功一张长图
download_one_image() {
    while true; do
        if ! check_network; then sleep 2; continue; fi
        
        URL=$(get_random_url)
        if [[ ! "$URL" =~ ^http ]]; then sleep 1; continue; fi

        TEMP_FILENAME="temp_$(date +%s%N)_$RANDOM"
        TEMP_PATH="$CACHE_DIR/$TEMP_FILENAME"
        
        curl -s -L --fail --connect-timeout 5 --max-time 15 -o "$TEMP_PATH" "$URL"

        if is_valid_image "$TEMP_PATH"; then
            FINAL_FILENAME="waifu_$(date +%s%N)_$RANDOM.jpg"
            FINAL_PATH="$CACHE_DIR/$FINAL_FILENAME"
            
            if convert_to_jpg "$TEMP_PATH" "$FINAL_PATH"; then
                rm -f "$TEMP_PATH"
                return 0
            else
                rm -f "$TEMP_PATH" "$FINAL_PATH"
            fi
        else
            rm -f "$TEMP_PATH"
        fi
        sleep 0.3
    done
}

background_job() {
    (
        trap '' HUP
        flock -n 200 || exit 1

        while true; do
            if ! check_network; then sleep 3; continue; fi
            
            CURRENT_COUNT=$(find "$CACHE_DIR" -maxdepth 1 -name "*.jpg" 2>/dev/null | wc -l)
            
            if [ "$CURRENT_COUNT" -lt "$MIN_TRIGGER_LIMIT" ]; then
                for ((i=1; i<=DOWNLOAD_BATCH_SIZE; i++)); do
                    download_one_image
                    sleep 0.2
                done
            else
                break
            fi
        done

        FINAL_COUNT=$(find "$CACHE_DIR" -maxdepth 1 -name "*.jpg" 2>/dev/null | wc -l)
        if [ "$FINAL_COUNT" -gt "$MAX_CACHE_LIMIT" ]; then
            DELETE_START_LINE=$((MAX_CACHE_LIMIT + 1))
            ls -tp "$CACHE_DIR"/*.jpg 2>/dev/null | tail -n +$DELETE_START_LINE | xargs -I {} rm -- "{}"
        fi
    ) 200>"$LOCK_FILE"
}

# --- 4. 主程序 ---
shopt -s nullglob
FILES=("$CACHE_DIR"/*.jpg)
NUM_FILES=${#FILES[@]}
shopt -u nullglob

SELECTED_IMG=""

if [ "$NUM_FILES" -gt 0 ]; then
    RAND_INDEX=$((RANDOM % NUM_FILES))
    SELECTED_IMG="${FILES[$RAND_INDEX]}"
    background_job >/dev/null 2>&1 &
    disown
else
    echo "正在下载长图，请稍等..."
    download_one_image

    shopt -s nullglob
    FILES=("$CACHE_DIR"/*.jpg)
    shopt -u nullglob
    if [ ${#FILES[@]} -gt 0 ]; then
        SELECTED_IMG="${FILES[0]}"
        background_job >/dev/null 2>&1 &
        disown
    fi
fi

# 运行
if [ -n "$SELECTED_IMG" ] && [ -f "$SELECTED_IMG" ] && is_valid_image "$SELECTED_IMG"; then
    fastfetch --logo "$SELECTED_IMG" --logo-preserve-aspect-ratio true "${ARGS_FOR_FASTFETCH[@]}"
    mv "$SELECTED_IMG" "$USED_DIR/"

    USED_COUNT=$(find "$USED_DIR" -maxdepth 1 -name "*.jpg" 2>/dev/null | wc -l)
    if [ "$USED_COUNT" -gt "$MAX_USED_LIMIT" ]; then
        SKIP_LINES=$((MAX_USED_LIMIT + 1))
        ls -tp "$USED_DIR"/*.jpg 2>/dev/null | tail -n +$SKIP_LINES | xargs -I {} rm -- "{}"
    fi

    if [ "$CLEAN_CACHE_MODE" = true ]; then
        rm -rf "$HOME/.cache/fastfetch/images"
    fi
else
    echo "图片获取失败"
    fastfetch "${ARGS_FOR_FASTFETCH[@]}"
fi
