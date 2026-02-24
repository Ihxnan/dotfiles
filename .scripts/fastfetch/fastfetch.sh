#!/usr/bin/env bash
# 脚本功能：
# 从随机老婆图片生成api下载图片，存在.cache/fastfetch_waifu目录。
# ✅ 核心优化：优先本地缓存随机调用，下载失败时绝对有图可用，不会空白
# ✅ 运行时如果库存不足，会在后台补货；如果库存超限，会清理旧图；下载失败自动重试，彻底杜绝无图问题

# --- 1. 配置区域 (在此修改数值) ---
CACHE_DIR="$HOME/.cache/fastfetch_waifu"
LOCK_FILE="/tmp/fastfetch_waifu.lock"

# 每次补货下载多少张
DOWNLOAD_BATCH_SIZE=10
# 最大库存上限
MAX_CACHE_LIMIT=100
# 库存少于多少张时开始补货
MIN_TRIGGER_LIMIT=60
# 单张图片下载失败的重试次数
DOWNLOAD_RETRY=3
# 图片下载超时时间
DOWNLOAD_TIMEOUT=10

mkdir -p "$CACHE_DIR"
shopt -s nullglob nocaseglob

# --- 2. 核心函数 ---
# 获取随机的图片API地址，3个源随机切换，增加成功率
get_random_url() {
    local TIMEOUT_PARAM="--connect-timeout ${DOWNLOAD_TIMEOUT} --max-time $((DOWNLOAD_TIMEOUT * 2)) -s"
    local RAND_API=$(((RANDOM % 3) + 1))
    local PIC_URL=""
    case ${RAND_API} in
        1) PIC_URL=$(curl ${TIMEOUT_PARAM} "https://api.waifu.im/search?included_tags=waifu&is_nsfw=false" | jq -r '.images[0].url') ;;
        2) PIC_URL=$(curl ${TIMEOUT_PARAM} "https://nekos.best/api/v2/waifu" | jq -r '.results[0].url') ;;
        3) PIC_URL=$(curl ${TIMEOUT_PARAM} "https://api.waifu.pics/sfw/waifu" | jq -r '.url') ;;
    esac
    # 返回有效的http链接，否则返回空
    echo "${PIC_URL}" | grep -E "^https?://" | head -n1
}

# 下载单张图片 + 重试机制 + 严格有效性校验
download_one_image() {
    local retry=0
    local img_url=""
    local filename="waifu_$(date +%s%N)_$RANDOM.jpg"
    local target="${CACHE_DIR}/${filename}"

    # 循环重试下载，直到成功/重试耗尽
    while [[ ${retry} -lt ${DOWNLOAD_RETRY} ]]; do
        img_url=$(get_random_url)
        # 拿到有效链接才开始下载
        if [[ -n ${img_url} ]]; then
            curl -s -L --connect-timeout ${DOWNLOAD_TIMEOUT} --max-time $((DOWNLOAD_TIMEOUT*2)) -o "${target}" "${img_url}"
            # 校验1：文件非空
            if [[ -s "${target}" ]]; then
                # 校验2：必须是图片格式（过滤404/html空文件）
                if command -v file >/dev/null 2>&1; then
                    if file --mime-type "${target}" | grep -qE "image/(jpeg|jpg|png|webp)"; then
                        # 校验通过，直接返回成功
                        return 0
                    fi
                else
                    # 没有file命令，用后缀兜底
                    [[ ${img_url} =~ \.(jpg|jpeg|png|webp)$ ]] && return 0
                fi
            fi
        fi
        # 校验失败，删除无效文件，重试+1
        rm -f "${target}"
        retry=$((retry + 1))
        sleep 0.3
    done
    return 1
}

# 后台异步补货+清理，带文件锁防多进程冲突
background_job() {
    (
        flock -n 200 || exit 1
        # 统计当前有效图片数量
        local current_count=$(ls -1 "${CACHE_DIR}"/*.{jpg,jpeg,png,webp} 2>/dev/null | wc -l)
        
        # 库存不足，开始补货
        if [[ ${current_count} -lt ${MIN_TRIGGER_LIMIT} ]]; then
            local need_download=$(( MIN_TRIGGER_LIMIT - current_count + DOWNLOAD_BATCH_SIZE ))
            for ((i=1; i<=need_download; i++)); do
                download_one_image
                sleep 0.2
            done
        fi

        # 库存超限，清理旧图，保留最新的MAX_CACHE_LIMIT张
        local final_count=$(ls -1 "${CACHE_DIR}"/*.{jpg,jpeg,png,webp} 2>/dev/null | wc -l)
        if [[ ${final_count} -gt ${MAX_CACHE_LIMIT} ]]; then
            ls -tp "${CACHE_DIR}"/*.{jpg,jpeg,png,webp} 2>/dev/null | tail -n +$((MAX_CACHE_LIMIT + 1)) | xargs -I {} rm -f -- "{}"
        fi
    ) 200>"${LOCK_FILE}"
}

# --- 3. 主程序核心逻辑【重点修改：彻底解决失败问题】---
# 第一步：获取本地所有缓存图片，这一步是优先级最高的，绝对不会失败
ALL_IMGS=("$CACHE_DIR"/*.jpg "$CACHE_DIR"/*.jpeg "$CACHE_DIR"/*.png "$CACHE_DIR"/*.webp)
NUM_IMGS=${#ALL_IMGS[@]}
SELECTED_IMG=""

# ✅ 核心优化1：只要本地有图，就100%随机选一张，永不失败
if [[ ${NUM_IMGS} -gt 0 ]]; then
    RAND_INDEX=$((RANDOM % NUM_IMGS))
    SELECTED_IMG="${ALL_IMGS[RAND_INDEX]}"
fi

# ✅ 核心优化2：后台异步补货/清理，不阻塞主程序，不影响图片显示速度
background_job >/dev/null 2>&1 &

# ✅ 核心优化3：就算本地无图，也同步下载一张保底，直到下载成功
if [[ -z ${SELECTED_IMG} ]]; then
    echo -e "\033[36m[老婆库存] 本地无图，正在获取新老婆...\033[0m"
    # 循环下载，直到拿到有效图片
    while true; do
        download_one_image && break
        sleep 0.5
    done
    # 重新获取图片列表，选中刚下载的
    ALL_IMGS=("$CACHE_DIR"/*.jpg "$CACHE_DIR"/*.jpeg "$CACHE_DIR"/*.png "$CACHE_DIR"/*.webp)
    SELECTED_IMG="${ALL_IMGS[0]}"
fi

# 运行Fastfetch显示图片，保留所有传入参数
if [[ -n ${SELECTED_IMG} && -f ${SELECTED_IMG} ]]; then
    fastfetch --logo "${SELECTED_IMG}" --logo-preserve-aspect-ratio true "$@"
    # 保留阅后即焚功能（用一张删一张，保证库存流动）
    rm -f "${SELECTED_IMG}"
else
    # 终极兜底：就算所有操作都失败，也显示默认logo，永不报错
    fastfetch "$@"
fi

# 还原shell配置
shopt -u nullglob nocaseglob
exit 0
