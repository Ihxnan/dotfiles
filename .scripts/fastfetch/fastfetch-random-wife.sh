#!/bin/bash
# 脚本功能：
# 从随机老婆图片生成 API 下载图片并使用 Fastfetch 展示。
# 特性：支持 NSFW 模式，支持自动补货，支持已用图片归档与自动清理，支持终端关闭后继续后台补货，图片强制转换为JPG格式。

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

# 图片下载重试次数（新增）
DOWNLOAD_RETRY_TIMES=3
# 最小有效图片尺寸（宽/高至少一个大于此值，单位px）
MIN_IMAGE_DIMENSION=100

# ===========================================

# --- 0. 依赖检查 ---
check_dependencies() {
    # 检查必要命令是否存在（优先检查 magick，兼容 IMv7；无则检查 convert，兼容 IMv6）
    local required_cmds=("curl" "jq" "file")
    local img_cmd=""
    
    # 优先检测 magick (IMv7)
    if command -v magick >/dev/null 2>&1; then
        img_cmd="magick"
    elif command -v convert >/dev/null 2>&1; then
        img_cmd="convert"
    else
        echo "错误：缺少 ImageMagick 工具（magick/convert），请先安装！"
        echo "Ubuntu/Debian: sudo apt install imagemagick curl jq file"
        echo "CentOS/RHEL: sudo dnf install ImageMagick curl jq file"
        echo "macOS: brew install curl jq imagemagick file"
        exit 1
    fi

    # 检查其他依赖
    for cmd in "${required_cmds[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo "错误：缺少必要工具 $cmd，请先安装！"
            echo "Ubuntu/Debian: sudo apt install curl jq imagemagick file"
            echo "CentOS/RHEL: sudo dnf install curl jq ImageMagick file"
            echo "macOS: brew install curl jq imagemagick file"
            exit 1
        fi
    done

    # 导出图片处理命令，供后续函数使用
    export IMG_CONVERT_CMD="$img_cmd"
}

# 执行依赖检查
check_dependencies

# --- 1. 参数解析与模式设置 ---

NSFW_MODE=false
# 检查环境变量
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

# 根据模式区分缓存目录和锁文件
if [ "$NSFW_MODE" = true ]; then
    CACHE_DIR="$HOME/.cache/fastfetch_waifu_nsfw"
    LOCK_FILE="/tmp/fastfetch_waifu_nsfw.lock"
else
    CACHE_DIR="$HOME/.cache/fastfetch_waifu"
    LOCK_FILE="/tmp/fastfetch_waifu.lock"
fi

# 定义已使用目录
USED_DIR="$CACHE_DIR/used"

mkdir -p "$CACHE_DIR"
mkdir -p "$USED_DIR"

# --- 3. 核心函数 ---

# [新增] 网络连通性检测，防止没网时阻塞终端或后台死等
check_network() {
    curl -s --connect-timeout 2 "https://1.1.1.1" >/dev/null 2>&1
    return $?
}

get_random_url() {
    local TIMEOUT="--connect-timeout 5 --max-time 15"
    RAND=$(((RANDOM % 3) + 1))

    if [ "$NSFW_MODE" = true ]; then
        # === NSFW API ===
        case $RAND in
        1) curl -s $TIMEOUT "https://api.waifu.im/search?included_tags=waifu&is_nsfw=true" | jq -r '.images[0].url' ;;
        2) curl -s $TIMEOUT "https://api.waifu.pics/nsfw/waifu" | jq -r '.url' ;;
        3) curl -s $TIMEOUT "https://api.waifu.pics/nsfw/neko" | jq -r '.url' ;;
        esac
    else
        # === SFW (正常) API ===
        case $RAND in
        1) curl -s $TIMEOUT "https://api.waifu.im/search?included_tags=waifu&is_nsfw=false" | jq -r '.images[0].url' ;;
        2) curl -s $TIMEOUT "https://nekos.best/api/v2/waifu" | jq -r '.results[0].url' ;;
        3) curl -s $TIMEOUT "https://api.waifu.pics/sfw/waifu" | jq -r '.url' ;;
        esac
    fi
}

# [新增] 校验图片是否有效（完整且尺寸正常）
is_valid_image() {
    local input_file="$1"
    
    # 1. 检查文件是否存在且非空
    if [ ! -s "$input_file" ]; then
        return 1
    fi
    
    # 2. 检查是否为有效图片文件（通过file命令）
    local file_type=$(file -b --mime-type "$input_file")
    if [[ ! "$file_type" =~ ^image/ ]]; then
        return 1
    fi
    
    # 3. 检查图片尺寸是否正常（宽/高至少一个大于MIN_IMAGE_DIMENSION）
    local width height
    if [ "$IMG_CONVERT_CMD" = "magick" ]; then
        width=$($IMG_CONVERT_CMD identify -format "%w" "$input_file" 2>/dev/null)
        height=$($IMG_CONVERT_CMD identify -format "%h" "$input_file" 2>/dev/null)
    else
        width=$(identify -format "%w" "$input_file" 2>/dev/null)
        height=$(identify -format "%h" "$input_file" 2>/dev/null)
    fi
    
    # 尺寸读取失败 或 尺寸过小，判定为无效
    if [ -z "$width" ] || [ -z "$height" ] || [ "$width" -le "$MIN_IMAGE_DIMENSION" ] || [ "$height" -le "$MIN_IMAGE_DIMENSION" ]; then
        return 1
    fi
    
    return 0
}

# [核心修改] 新增图片格式转换函数（兼容 magick/convert）
convert_to_jpg() {
    local input_file="$1"
    local output_file="$2"
    
    # 使用动态获取的图片处理命令（magick 或 convert）
    $IMG_CONVERT_CMD "$input_file" -quality 95 -strip "$output_file" >/dev/null 2>&1
    
    # 检查转换是否成功，且转换后的文件有效
    if [ $? -eq 0 ] && is_valid_image "$output_file"; then
        return 0
    else
        return 1
    fi
}

download_one_image() {
    local retry=0
    local success=0
    
    # 重试机制：最多重试DOWNLOAD_RETRY_TIMES次
    while [ $retry -lt $DOWNLOAD_RETRY_TIMES ] && [ $success -eq 0 ]; do
        URL=$(get_random_url)
        if [[ "$URL" =~ ^http ]]; then
            # 生成临时文件名（用于下载原始文件）
            TEMP_FILENAME="temp_$(date +%s%N)_$RANDOM"
            TEMP_PATH="$CACHE_DIR/$TEMP_FILENAME"
            
            # 下载原始文件（添加--fail确保非200状态码时返回失败）
            curl -s -L --fail --connect-timeout 5 --max-time 15 -o "$TEMP_PATH" "$URL"

            # 校验原始文件是否有效
            if is_valid_image "$TEMP_PATH"; then
                # 生成最终的JPG文件名
                FINAL_FILENAME="waifu_$(date +%s%N)_$RANDOM.jpg"
                FINAL_PATH="$CACHE_DIR/$FINAL_FILENAME"
                
                # 转换为JPG格式
                if convert_to_jpg "$TEMP_PATH" "$FINAL_PATH"; then
                    # 转换成功，标记为成功，删除临时文件
                    success=1
                    rm -f "$TEMP_PATH"
                else
                    # 转换失败，清理所有文件，准备重试
                    rm -f "$TEMP_PATH" "$FINAL_PATH"
                    retry=$((retry + 1))
                fi
            else
                # 原始文件无效，清理临时文件，准备重试
                rm -f "$TEMP_PATH"
                retry=$((retry + 1))
            fi
        else
            # URL无效，重试
            retry=$((retry + 1))
        fi
    done
    
    return $success
}

background_job() {
    (
        # [核心修复 1] 忽略终端关闭带来的 SIGHUP 信号
        trap '' HUP

        flock -n 200 || exit 1

        # [新增] 网络检查，没网就悄悄退出，不占后台资源
        if ! check_network; then
            exit 0
        fi

        # 1. 补货检查
        CURRENT_COUNT=$(find "$CACHE_DIR" -maxdepth 1 -name "*.jpg" 2>/dev/null | wc -l)

        if [ "$CURRENT_COUNT" -lt "$MIN_TRIGGER_LIMIT" ]; then
            for ((i = 1; i <= DOWNLOAD_BATCH_SIZE; i++)); do
                download_one_image
                sleep 0.5
            done
        fi

        # 2. 清理过多库存
        FINAL_COUNT=$(find "$CACHE_DIR" -maxdepth 1 -name "*.jpg" 2>/dev/null | wc -l)
        if [ "$FINAL_COUNT" -gt "$MAX_CACHE_LIMIT" ]; then
            DELETE_START_LINE=$((MAX_CACHE_LIMIT + 1))
            ls -tp "$CACHE_DIR"/*.jpg 2>/dev/null | tail -n +$DELETE_START_LINE | xargs -I {} rm -- "{}"
        fi

    ) 200>"$LOCK_FILE"
}

# --- 4. 主程序逻辑 ---

shopt -s nullglob
FILES=("$CACHE_DIR"/*.jpg)
NUM_FILES=${#FILES[@]}
shopt -u nullglob

SELECTED_IMG=""

if [ "$NUM_FILES" -gt 0 ]; then
    # 有库存，随机选一张
    RAND_INDEX=$((RANDOM % NUM_FILES))
    SELECTED_IMG="${FILES[$RAND_INDEX]}"

    # 后台补货
    background_job >/dev/null 2>&1 &
    # [核心修复 2] 将任务从终端作业列表中移除，脱离终端控制
    disown

else
    # 没库存，提示语更改
    echo "库存不够啦！正在去搬运新的图片，请稍等哦..."

    # 无网情况下的容错处理
    if check_network; then
        download_one_image
    else
        echo "网络好像不太通畅，无法下载新图片 QAQ"
    fi

    shopt -s nullglob
    FILES=("$CACHE_DIR"/*.jpg)
    shopt -u nullglob

    if [ ${#FILES[@]} -gt 0 ]; then
        SELECTED_IMG="${FILES[0]}"
        background_job >/dev/null 2>&1 &
        # [核心修复 2] 将任务从终端作业列表中移除
        disown
    fi
fi

# 运行 Fastfetch
if [ -n "$SELECTED_IMG" ] && [ -f "$SELECTED_IMG" ] && is_valid_image "$SELECTED_IMG"; then

    # 显示图片
    fastfetch --logo "$SELECTED_IMG" --logo-preserve-aspect-ratio true "${ARGS_FOR_FASTFETCH[@]}"

    # === 逻辑：移动到 used 目录 ===
    mv "$SELECTED_IMG" "$USED_DIR/"

    # === 逻辑：检查 used 目录数量并清理 ===
    USED_COUNT=$(find "$USED_DIR" -maxdepth 1 -name "*.jpg" 2>/dev/null | wc -l)

    if [ "$USED_COUNT" -gt "$MAX_USED_LIMIT" ]; then
        # 计算需要保留的文件行数 (跳过最新的 MAX_USED_LIMIT 个)
        SKIP_LINES=$((MAX_USED_LIMIT + 1))
        # ls -tp 按时间倒序排列(新->旧)，tail 取出旧文件，xargs 删除
        ls -tp "$USED_DIR"/*.jpg 2>/dev/null | tail -n +$SKIP_LINES | xargs -I {} rm -- "{}"
    fi

    # 检查是否开启清理 Fastfetch 内部缓存 (仅清理缩略图缓存，不删原图)
    if [ "$CLEAN_CACHE_MODE" = true ]; then
        rm -rf "$HOME/.cache/fastfetch/images"
    fi
else
    # 失败提示语更改
    echo "呜呜... 图片获取失败了，这次只能先显示默认的 Logo 啦 QAQ"
    fastfetch "${ARGS_FOR_FASTFETCH[@]}"
fi
