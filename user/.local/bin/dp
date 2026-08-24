#!/usr/bin/env bash
set -euo pipefail

# ── colors ───────────────────────────────────────────────────
# $'…' makes these real ESC sequences so they also work inside heredocs.
RED=$'\033[31m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
CYAN=$'\033[36m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
RESET=$'\033[0m'

# ── platform ─────────────────────────────────────────────────
# Detect Windows (Git Bash / MSYS2 / Cygwin) vs Unix-like so the
# executable suffix adapts automatically. Same script runs on both.
PLATFORM="linux"
case "$(uname -s 2>/dev/null)" in
    MINGW* | MSYS* | CYGWIN*) PLATFORM="windows" ;;
esac
EXE=""
[[ $PLATFORM == "windows" ]] && EXE=".exe"

# Per-instance token (PID) so two dp runs never clash over the
# intermediate file names.
TOKEN=$$

# Output directory for all intermediate artifacts (compiled binaries and
# per-round data/ans/test files), overridable with -d/--dir. The final
# diff report is always written to the current directory. Default: /tmp.
TMP_DIR="/tmp"

# compiled binaries (".exe" on Windows, no suffix on Linux) and per-round
# data/ans/test files. All paths are derived from TMP_DIR and recomputed
# after option parsing (set_temp_paths is called again once -d/--dir has
# been applied), so the two call sites stay in sync.
set_temp_paths() {
    OUT_DATA="$TMP_DIR/data.$TOKEN$EXE"
    OUT_ANS="$TMP_DIR/ans.$TOKEN$EXE"
    OUT_TEST="$TMP_DIR/test.$TOKEN$EXE"
    OUT_CMP="$TMP_DIR/cmp.$TOKEN$EXE"
    DATA_FILE="$TMP_DIR/data.$TOKEN.txt"
    ANS_FILE="$TMP_DIR/ans.$TOKEN.txt"
    TEST_FILE="$TMP_DIR/test.$TOKEN.txt"
}
set_temp_paths

MAX_ATTEMPTS=100
INFINITE=0    # -N: run forever until a counterexample is found
TIMEOUT_SEC=0 # seconds per run; 0 = no timeout
OPT_LEVEL=3
CXX_STD="c++17"

# comparison settings
EPS=1e-6        # float comparison tolerance (auto mode)
CMP_MODE="auto" # auto: numeric compare by float tolerance | strict: byte-level | custom: user comparator
CMP_SRC=""      # custom comparator source; auto-detected from check.cpp/check.py

# source files
# Defaults are resolved by availability in the working directory: prefer
# the .cpp file, fall back to .py (e.g. ans.cpp -> ans.py). The compile
# step reports a missing file when neither exists.
pick_src() {
    local base="$1"
    if [[ -f "$base.cpp" ]]; then
        echo "$base.cpp"
    elif [[ -f "$base.py" ]]; then
        echo "$base.py"
    else
        echo "$base.cpp" # compile step will report the missing file
    fi
}
ANS_SRC="$(pick_src ans)"
TEST_SRC="$(pick_src test)"
DATA_SRC="$(pick_src data)"
# the custom comparator has no must-exist default: it only activates when
# check.cpp / check.py is present (or -C/--cmp-src is given explicitly)
if [[ -f "check.cpp" ]]; then
    CMP_SRC="check.cpp"
    CMP_MODE="custom"
elif [[ -f "check.py" ]]; then
    CMP_SRC="check.py"
    CMP_MODE="custom"
fi

# the diff report is named after the tested program and stays next to the
# sources (always kept on mismatch); computed after option parsing.

# ── i18n ─────────────────────────────────────────────────────
# Language selection (-l/--lang en|zh). Default: en.
LANG_SETTING="en"

# Terminal display width: ASCII=1 column, CJK/full-width=2 columns.
disp_width() {
    local s="$1" i w=0 c
    local LC_COLLATE=C
    for ((i = 0; i < ${#s}; i++)); do
        c="${s:i:1}"
        if [[ "$c" > $'\x7f' ]]; then
            w=$((w + 2))
        else
            w=$((w + 1))
        fi
    done
    echo "$w"
}

# Left-align $1 to display width $2.
pad() {
    local s="$1" w="$2" sw p
    sw="$(disp_width "$s")"
    p=$((w - sw))
    ((p < 0)) && p=0
    printf '%s%*s' "$s" "$p" ''
}

# One-line colored box: box_line <box_color> <text_color> <text>
box_line() {
    local box_c="$1" text_c="$2" text="$3"
    local w
    w="$(disp_width "$text")"
    local total=$((w + 8))
    local body
    printf -v body '%*s' $((total - 2)) ''
    body="${body// /─}"
    printf "${box_c}┌%s┐${RESET}\n" "$body"
    printf "${box_c}│${RESET}  ${text_c}%s${RESET}%*s  ${box_c}│${RESET}\n" "$text" $((total - w - 6)) ""
    printf "${box_c}└%s┘${RESET}\n" "$body"
}

# Multi-line framed box: box_block <color> <line>... — same box style as
# box_line but for any number of lines; used for the pass summary.
box_block() {
    local color="$1"
    shift
    local max_w=0 w line
    for line in "$@"; do
        w="$(disp_width "$line")"
        ((w > max_w)) && max_w=$w
    done
    local content_w=$((max_w + 2))
    local bar
    printf -v bar '%*s' $((content_w + 2)) ''
    bar="${bar// /─}"
    printf "${color}┌%s┐${RESET}\n" "$bar"
    for line in "$@"; do
        printf "${color}│${RESET} %s ${color}│${RESET}\n" "$(pad "$line" "$content_w")"
    done
    printf "${color}└%s┘${RESET}\n" "$bar"
}

setup_i18n() {
    if [[ "$LANG_SETTING" == "zh" ]]; then
        MSG_USAGE="用法：%s [选项]"
        MSG_OPTIONS_HEADER="选项："
        MSG_GROUP_RUN="运行："
        MSG_GROUP_COMPILE="编译："
        MSG_GROUP_SOURCES="源文件："
        MSG_GROUP_COMPARE="比较："
        MSG_GROUP_OUTPUT="输出："
        MSG_GROUP_OTHER="其他："
        MSG_EXAMPLES="示例："
        MSG_TOOL_DESC="对拍程序：自动生成测试数据，对比 ans.cpp 与 test.cpp 的输出。"
        MSG_OPT_ATTEMPTS="测试轮数（默认：$MAX_ATTEMPTS）"
        MSG_OPT_INFINITE="无限对拍：持续运行直到发现反例（忽略 -n）"
        MSG_OPT_DIR="中间文件输出目录（默认：/tmp）"
        MSG_OPT_STD="C++ 标准（默认：$CXX_STD）"
        MSG_OPT_EPS="浮点比较误差阈值（默认：$EPS）"
        MSG_OPT_CMP="比较模式：auto | strict | custom（默认：$CMP_MODE）"
        MSG_OPT_CMP_SRC="自定义比较器源文件，按后缀支持 C/C++/Python（默认：check.cpp/check.py，若存在）"
        MSG_OPT_ANS="参考答案源文件，按后缀支持 C/C++/Python（默认：$ANS_SRC）"
        MSG_OPT_TEST="被测程序源文件，按后缀支持 C/C++/Python（默认：$TEST_SRC）"
        MSG_OPT_GEN="数据生成器源文件，按后缀支持 C/C++/Python（默认：$DATA_SRC）"
        MSG_OPT_LEVEL="优化等级（默认：-O$OPT_LEVEL）"
        MSG_OPT_HELP="显示此帮助"
        MSG_OPT_LANG="输出语言（默认：$LANG_SETTING）"
        MSG_OPT_TIMEOUT="每次运行超时秒数，0 表示禁用（默认：$TIMEOUT_SEC）"
        MSG_EX_DEFAULT="默认：100 轮"
        MSG_EX_MORE="更多轮数"
        MSG_EX_CUSTOM_SRC="自定义源文件"
        MSG_EX_CXX20="用 C++20 编译"
        MSG_EX_LOOSEN="放宽误差阈值"
        MSG_EX_STRICT="字节级严格比较"
        MSG_EX_CUSTOM_CMP="自定义比较器"
        MSG_EX_PYTHON="Python 源文件"
        MSG_EX_DIR="中间文件放当前目录"
        MSG_CMP_MODES="比较模式："
        MSG_CMP_AUTO="数字 token 按浮点误差比较，其余严格按字符串比较（默认）"
        MSG_CMP_STRICT="字节级严格比较，等价于原 cmp -s 行为"
        MSG_CMP_CUSTOM="用 -C/--cmp-src 指定的自定义比较器：<input> <ans> <test>，退出码 0 表示一致"
        MSG_COMPILING="正在编译：%s ..."
        MSG_COMPILE_FAIL="编译失败：%s"
        MSG_COMPILE_FAIL_CMP="编译失败：比较器"
        MSG_COMPILE_OK="全部程序编译成功！"
        MSG_RUN="运行"
        MSG_PRESS_CTRL_C="按 Ctrl+C 可随时中断。"
        MSG_CRASHED="%s 崩溃"
        MSG_TIMEOUT="%s 超时（%s 秒）"
        MSG_CE_FOUND="发现反例！"
        MSG_ATTEMPT="第 %d 轮"
        MSG_CE_FOUND_TITLE="发现反例（第 %s 轮）"
        MSG_RE_FOUND="运行时错误！"
        MSG_RE_FOUND_TITLE="运行时错误（第 %s 轮）"
        MSG_REASON="原因"
        MSG_TIME="时间"
        MSG_MAX_ATTEMPTS="最大轮数"
        MSG_CMP_MODE="比较模式"
        MSG_EPS="误差"
        MSG_INPUT="输入"
        MSG_EXPECTED="期望输出"
        MSG_GOT="实际输出"
        MSG_SPACES_NOTE="[空格 → '.', tab → '→']"
        MSG_COMPARATOR_REPORT="比较器报告："
        MSG_INTERRUPT="检测到中断，正在清理……"
        MSG_INTERRUPT_TITLE="对拍中断（第 %s 轮）"
        MSG_DIFF_PRESERVED="反例已保留：%s"
        MSG_TEMP_DELETED="临时文件已删除。"
        MSG_DIFF_REPORT="Diff 报告：%s"
        MSG_ALL_PASSED="全部 %s 轮测试通过。"
        MSG_AVG_TIME="平均用时（毫秒/次）：ans=%s  test=%s"
        MSG_RUN_TIME="本轮耗时"
        MSG_COMPILE_FLAGS="编译参数"
        MSG_RANGE="耗时范围"
        MSG_ERR_UNKNOWN_LONG="错误：未知的长选项 '--%s'"
        MSG_ERR_UNKNOWN="错误：未知的选项 '-%s'"
        MSG_ERR_REQUIRES="错误：选项 '-%s' 需要一个参数"
        MSG_ERR_CMP_MODE="错误：无效的 --cmp 模式 '%s'（应为 'auto'、'strict' 或 'custom'）"
        MSG_ERR_CMP_SRC="错误：找不到比较器源文件 '%s'"
        MSG_ERR_CMP_SRC_REQ="错误：比较模式 'custom' 需要 -C/--cmp-src 指定比较器源文件"
        MSG_ERR_LANG="错误：无效的 --lang 值 '%s'（应为 'en' 或 'zh'）"
        MSG_ERR_ATTEMPTS="错误：无效的 --max-attempts '%s'（应为非负整数）"
        MSG_ERR_EPS="错误：无效的 --eps '%s'（应为非负浮点数）"
        MSG_ERR_LONG_REQUIRES="错误：选项 '--%s' 需要一个参数"
        MSG_ERR_DIR="错误：无法创建输出目录 '%s'"
        MSG_ERR_OPT="错误：无效的优化等级 '%s'（应为 0、1、2 或 3）"
        MSG_ERR_TIMEOUT="错误：无效的 --timeout 值 '%s'（应为非负整数，0 表示禁用）"
        MSG_WARN_NO_TIMEOUT="警告：未找到 timeout 命令，已禁用超时"
        MSG_ERR_NO_PYTHON="错误：使用了 .py 源文件，但找不到 Python 解释器（python3/python）"
    else
        MSG_USAGE="Usage: %s [options]"
        MSG_OPTIONS_HEADER="Options:"
        MSG_GROUP_RUN="Run:"
        MSG_GROUP_COMPILE="Compile:"
        MSG_GROUP_SOURCES="Sources:"
        MSG_GROUP_COMPARE="Compare:"
        MSG_GROUP_OUTPUT="Output:"
        MSG_GROUP_OTHER="Other:"
        MSG_EXAMPLES="Examples:"
        MSG_TOOL_DESC="Stress-test tool - auto-generates test data and compares output of ans.cpp vs test.cpp."
        MSG_OPT_ATTEMPTS="Number of test rounds (default: $MAX_ATTEMPTS)"
        MSG_OPT_INFINITE="Infinite mode: keep running until a counterexample is found (ignores -n)"
        MSG_OPT_DIR="Output directory for intermediate files (default: /tmp)"
        MSG_OPT_STD="C++ standard (default: $CXX_STD)"
        MSG_OPT_EPS="Float comparison tolerance (default: $EPS)"
        MSG_OPT_CMP="Comparison mode: auto | strict | custom (default: $CMP_MODE)"
        MSG_OPT_CMP_SRC="Custom comparator source, C/C++/Python by extension (default: check.cpp/check.py when present)"
        MSG_OPT_ANS="Reference solution source, C/C++/Python by extension (default: $ANS_SRC)"
        MSG_OPT_TEST="Tested program source, C/C++/Python by extension (default: $TEST_SRC)"
        MSG_OPT_GEN="Data generator source, C/C++/Python by extension (default: $DATA_SRC)"
        MSG_OPT_LEVEL="Optimization level (default: -O$OPT_LEVEL)"
        MSG_OPT_HELP="Show this help"
        MSG_OPT_LANG="Output language (default: $LANG_SETTING)"
        MSG_OPT_TIMEOUT="Timeout in seconds per run, 0 to disable (default: $TIMEOUT_SEC)"
        MSG_EX_DEFAULT="default: 100 rounds"
        MSG_EX_MORE="more rounds"
        MSG_EX_CUSTOM_SRC="custom sources"
        MSG_EX_CXX20="compile with C++20"
        MSG_EX_LOOSEN="loosen tolerance"
        MSG_EX_STRICT="byte-level comparison"
        MSG_EX_CUSTOM_CMP="custom comparator"
        MSG_EX_PYTHON="python sources"
        MSG_EX_DIR="intermediates in current dir"
        MSG_CMP_MODES="Comparison modes:"
        MSG_CMP_AUTO="numeric tokens compared by float tolerance, everything else strictly as strings (default)"
        MSG_CMP_STRICT="byte-level strict comparison, equivalent to the old cmp -s behavior"
        MSG_CMP_CUSTOM="use the custom comparator given by -C/--cmp-src: <input> <ans> <test>, exit 0 means match"
        MSG_COMPILING="Compiling with: %s ..."
        MSG_COMPILE_FAIL="Compilation failed: %s"
        MSG_COMPILE_FAIL_CMP="Compilation failed: comparator"
        MSG_COMPILE_OK="All programs compiled successfully!"
        MSG_RUN="Run"
        MSG_PRESS_CTRL_C="Press Ctrl+C to interrupt."
        MSG_CRASHED="%s crashed"
        MSG_TIMEOUT="%s timed out after %s s"
        MSG_CE_FOUND="Counterexample found!"
        MSG_ATTEMPT="Attempt %d"
        MSG_CE_FOUND_TITLE="Counterexample Found - Attempt %s"
        MSG_RE_FOUND="Runtime error!"
        MSG_RE_FOUND_TITLE="Runtime Error - Attempt %s"
        MSG_REASON="Reason"
        MSG_TIME="Time"
        MSG_MAX_ATTEMPTS="Max attempts"
        MSG_CMP_MODE="Cmp mode"
        MSG_EPS="Eps"
        MSG_INPUT="Input"
        MSG_EXPECTED="Expected"
        MSG_GOT="Got"
        MSG_SPACES_NOTE="[spaces → '.', tabs → '→']"
        MSG_COMPARATOR_REPORT="Comparator report:"
        MSG_INTERRUPT="Interrupt detected, cleaning up..."
        MSG_INTERRUPT_TITLE="Run Interrupted - Attempt %s"
        MSG_DIFF_PRESERVED="Diff case preserved: %s"
        MSG_TEMP_DELETED="Temporary files deleted."
        MSG_DIFF_REPORT="Diff report: %s"
        MSG_ALL_PASSED="All %s attempts passed."
        MSG_AVG_TIME="Avg time per attempt (ms): ans=%s  test=%s"
        MSG_RUN_TIME="This run"
        MSG_COMPILE_FLAGS="compile flags"
        MSG_RANGE="time range"
        MSG_ERR_UNKNOWN_LONG="Error: Unknown long option '--%s'"
        MSG_ERR_UNKNOWN="Error: Unknown option '-%s'"
        MSG_ERR_REQUIRES="Error: Option '-%s' requires an argument"
        MSG_ERR_CMP_MODE="Error: invalid --cmp mode '%s' (expected 'auto', 'strict' or 'custom')"
        MSG_ERR_CMP_SRC="Error: comparator source file not found: '%s'"
        MSG_ERR_CMP_SRC_REQ="Error: comparison mode 'custom' requires -C/--cmp-src to specify the comparator source"
        MSG_ERR_LANG="Error: invalid --lang '%s' (expected 'en' or 'zh')"
        MSG_ERR_ATTEMPTS="Error: invalid --max-attempts '%s' (expected a non-negative integer)"
        MSG_ERR_EPS="Error: invalid --eps '%s' (expected a non-negative float)"
        MSG_ERR_LONG_REQUIRES="Error: option '--%s' requires an argument"
        MSG_ERR_DIR="Error: cannot create output directory '%s'"
        MSG_ERR_OPT="Error: invalid optimization level '%s' (expected 0, 1, 2 or 3)"
        MSG_ERR_TIMEOUT="Error: invalid --timeout '%s' (expected a non-negative integer, 0 to disable)"
        MSG_WARN_NO_TIMEOUT="Warning: 'timeout' command not found, disabling timeout"
        MSG_ERR_NO_PYTHON="Error: .py sources in use but no Python interpreter found (python3/python)"
    fi
}

# ── helpers ──────────────────────────────────────────────────

usage() {
    local me="$(basename "$0")" rc="${1:-0}"
    setup_i18n
    cat <<EOF
${BOLD}$(printf "$MSG_USAGE" "$me")${RESET}

$MSG_TOOL_DESC

${BOLD}$MSG_OPTIONS_HEADER${RESET}
EOF
    printf "\n  ${BOLD}${CYAN}%s${RESET}\n" "$MSG_GROUP_RUN"
    printf "  ${CYAN}%-24s${RESET} %s\n" \
        "-n, --max-attempts <num>" "$MSG_OPT_ATTEMPTS" \
        "-N, --infinite" "$MSG_OPT_INFINITE" \
        "-T, --timeout <sec>" "$MSG_OPT_TIMEOUT"

    printf "\n  ${BOLD}${CYAN}%s${RESET}\n" "$MSG_GROUP_COMPILE"
    printf "  ${CYAN}%-24s${RESET} %s\n" \
        "-s, --std <standard>" "$MSG_OPT_STD" \
        "-O0..-O3" "$MSG_OPT_LEVEL"

    printf "\n  ${BOLD}${CYAN}%s${RESET}\n" "$MSG_GROUP_SOURCES"
    printf "  ${CYAN}%-24s${RESET} %s\n" \
        "-a, --ans <file>" "$MSG_OPT_ANS" \
        "-t, --test <file>" "$MSG_OPT_TEST" \
        "-g, --gen <file>" "$MSG_OPT_GEN"

    printf "\n  ${BOLD}${CYAN}%s${RESET}\n" "$MSG_GROUP_COMPARE"
    printf "  ${CYAN}%-24s${RESET} %s\n" \
        "-c, --cmp <mode>" "$MSG_OPT_CMP" \
        "-C, --cmp-src <file>" "$MSG_OPT_CMP_SRC" \
        "-e, --eps <num>" "$MSG_OPT_EPS"

    printf "\n  ${BOLD}${CYAN}%s${RESET}\n" "$MSG_GROUP_OUTPUT"
    printf "  ${CYAN}%-24s${RESET} %s\n" \
        "-d, --dir <path>" "$MSG_OPT_DIR" \
        "-l, --lang <lang>" "$MSG_OPT_LANG"

    printf "\n  ${BOLD}${CYAN}%s${RESET}\n" "$MSG_GROUP_OTHER"
    printf "  ${CYAN}%-24s${RESET} %s\n" \
        "-h, --help" "$MSG_OPT_HELP"

    cat <<EOF

${BOLD}$MSG_EXAMPLES${RESET}
EOF
    printf "  %-40s ${DIM}# %s${RESET}\n" \
        "$me" "$MSG_EX_DEFAULT" \
        "$me -n 5000" "$MSG_EX_MORE" \
        "$me -a brute.cpp -t solve.cpp -g gen.cpp" "$MSG_EX_CUSTOM_SRC" \
        "$me -s c++20 -O2" "$MSG_EX_CXX20" \
        "$me -e 1e-4" "$MSG_EX_LOOSEN" \
        "$me -c strict" "$MSG_EX_STRICT" \
        "$me -C checker.cpp" "$MSG_EX_CUSTOM_CMP" \
        "$me -a brute.py -t solve.py -g gen.py" "$MSG_EX_PYTHON" \
        "$me -d ." "$MSG_EX_DIR"
    cat <<EOF

${BOLD}$MSG_CMP_MODES${RESET}
  auto    $MSG_CMP_AUTO
  strict  $MSG_CMP_STRICT
  custom  $MSG_CMP_CUSTOM
EOF
    exit "$rc"
}

# Render one output file with spaces/tabs made visible ('.' / '→').
render_side() {
    local f="$1"
    awk '{ gsub(/ /, ".", $0); gsub(/\t/, "→", $0); print }' "$f"
}

write_diff_report() {
    local attempt=$1
    local cmp_detail=$2
    local kind="${3:-ce}"     # ce: counterexample | re: runtime error | int: interrupted
    local err_info="${4:-}"   # human-readable failure reason (re only)
    local stage="${5:-}"      # data|ans|test — which program failed (re only)

    # ── header box ─────────────────────────────────────────────
    # Width is derived from the widest content line, measured in
    # terminal display columns (CJK text is 2 columns), so the box
    # stays aligned in both languages.
    local title
    if [[ $kind == "re" ]]; then
        title="$(printf "$MSG_RE_FOUND_TITLE" "$attempt")"
    elif [[ $kind == "int" ]]; then
        title="$(printf "$MSG_INTERRUPT_TITLE" "$attempt")"
    else
        title="$(printf "$MSG_CE_FOUND_TITLE" "$attempt")"
    fi
    local t_line="$(printf '%s: %s' "$MSG_TIME" "$(date)")"
    local m_line="$(printf '%s: %s' "$MSG_MAX_ATTEMPTS" "$MAX_ATTEMPTS")"
    local c_line
    if [[ $kind == "re" ]]; then
        c_line="$(printf '%s: %s' "$MSG_REASON" "$err_info")"
    else
        c_line="$(printf '%s: %s    %s: %s' "$MSG_CMP_MODE" "$CMP_MODE" "$MSG_EPS" "$EPS")"
    fi
    local r_line
    if [[ $kind == "re" ]]; then
        # timing is partial or meaningless when a program crashed
        r_line="$(printf '%s: -' "$MSG_RUN_TIME")"
    else
        r_line="$(printf '%s: ans=%s ms  test=%s ms' \
            "$MSG_RUN_TIME" \
            "$(awk -v t="$LAST_ANS_NS" 'BEGIN { printf "%.3f", t / 1e6 }')" \
            "$(awk -v t="$LAST_TEST_NS" 'BEGIN { printf "%.3f", t / 1e6 }')")"
    fi

    local max_w=0 w line
    for line in "$title" "$t_line" "$m_line" "$c_line" "$r_line"; do
        w="$(disp_width "$line")"
        ((w > max_w)) && max_w=$w
    done

    local content_w=$((max_w + 2)) # breathing room inside the walls
    local box_w=$((content_w + 4)) # "│ " + content + " │"
    local bar_body
    printf -v bar_body '%*s' $((box_w - 2)) ''
    bar_body="${bar_body// /─}"
    local box_bar="┌${bar_body}┐"
    local box_sep="├${bar_body}┤"
    local box_bot="└${bar_body}┘"
    local sep
    printf -v sep '%*s' "$box_w" ''
    sep="${sep// /─}"

    {
        echo "$box_bar"
        printf "│ %s │\n" "$(pad "$title" "$content_w")"
        echo "$box_sep"
        printf "│ %s │\n" "$(pad "$t_line" "$content_w")"
        printf "│ %s │\n" "$(pad "$m_line" "$content_w")"
        printf "│ %s │\n" "$(pad "$c_line" "$content_w")"
        printf "│ %s │\n" "$(pad "$r_line" "$content_w")"
        echo "$box_bot"
        echo ""

        printf '◆ %s:\n' "$MSG_INPUT"
        echo "$sep"
        cat "$DATA_FILE"
        echo ""

        # a failed generator never produced a valid input, and a crashed
        # program may never have run (or produced output) at all, so guard
        # each side by file existence instead of rendering missing files
        if [[ $kind != "re" || $stage != "data" ]]; then
            if [[ -f "$ANS_FILE" ]]; then
                printf '◆ %s  %s:\n' "$MSG_EXPECTED" "$MSG_SPACES_NOTE"
                echo "$sep"
                render_side "$ANS_FILE"
                echo ""
            fi
            if [[ -f "$TEST_FILE" ]]; then
                printf '◆ %s  %s:\n' "$MSG_GOT" "$MSG_SPACES_NOTE"
                echo "$sep"
                render_side "$TEST_FILE"
                echo ""
            fi
        fi

        if [[ -n "$cmp_detail" ]]; then
            echo "◆ $MSG_COMPARATOR_REPORT"
            echo "$sep"
            echo "$cmp_detail"
            echo ""
        fi
    } >"$DIFF_CASE_FILE"
}

# Print the report on the terminal with section colors, leaving the report
# file itself plain (a txt file has no color support). Falls back to a
# plain cat when stdout is not a terminal.
cat_report() {
    local f="$1"
    if [[ ! -t 1 ]]; then
        cat "$f"
        return
    fi
    awk '
        BEGIN {
            RESET = "\033[0m"
            BOX   = "\033[36m"      # cyan: header frame
            TITLE = "\033[1;36m"    # bold cyan: section titles
            EXP   = "\033[1;32m"    # bold green: expected
            GOT   = "\033[1;31m"    # bold red: got
            CMP   = "\033[1;33m"    # bold yellow: comparator report
        }
        /^(┌|├|└|│)/ { printf "%s%s%s\n", BOX, $0, RESET; next }
        /^◆/ {
            if ($0 ~ /Expected|期望/) t = EXP
            else if ($0 ~ /Got|实际/) t = GOT
            else if ($0 ~ /Comparator|比较器/) t = CMP
            else t = TITLE
            printf "%s%s%s\n", t, $0, RESET
            next
        }
        { print }
    ' "$f"
}

# Remove build artifacts and per-round temp files (exact names, no globs).
remove_temp_files() {
    rm -f "$OUT_DATA" "$OUT_ANS" "$OUT_TEST" "$OUT_CMP" "$DATA_FILE" "$ANS_FILE" "$TEST_FILE"
}

# Terminate a background compile job AND its g++/python child. Killing just
# the job subshell can orphan the compiler, which keeps writing its output
# file after remove_temp_files ran and leaves a stray artifact behind.
kill_job_tree() {
    local pid="$1"
    if command -v pkill >/dev/null 2>&1; then
        pkill -TERM -P "$pid" 2>/dev/null || true
    fi
    kill "$pid" 2>/dev/null || true
    # escalate to KILL if the job is still around: TERM alone can leave
    # an orphaned compiler (no pkill, or a double-forked grandchild)
    # writing artifacts after remove_temp_files ran
    local i
    for ((i = 0; i < 5; i++)); do
        kill -0 "$pid" 2>/dev/null || return 0
        sleep 0.05
    done
    if command -v pkill >/dev/null 2>&1; then
        pkill -KILL -P "$pid" 2>/dev/null || true
    fi
    kill -KILL "$pid" 2>/dev/null || true
}

cleanup() {
    # 清掉进度条行，中断消息从新的一行开始（仅在终端绘制时）
    [[ -t 1 ]] && printf "\033[2K\r"
    echo ""
    echo "$MSG_INTERRUPT"
    # terminate any still-running child programs (data/ans/test) first
    local j
    for j in $(jobs -p); do
        kill_job_tree "$j"
    done
    wait 2>/dev/null || true
    # Ctrl+C/kill without a counterexample: keep the last round's data as
    # a diff report so the user can inspect where the run stopped. Only a
    # completed pass with no mismatch deletes everything.
    if [[ ! -f "$DIFF_CASE_FILE" && -f "$DATA_FILE" ]]; then
        box_line "$YELLOW" "$BOLD" "$(printf "$MSG_INTERRUPT_TITLE" "$count")"
        write_diff_report "$count" "" "int"
    fi
    remove_temp_files
    # the report is always kept once a diff case exists (found or interrupted)
    if [[ -f "$DIFF_CASE_FILE" ]]; then
        echo "$(printf "$MSG_DIFF_PRESERVED" "$DIFF_CASE_FILE")"
        echo ""
        printf "  ${BOLD}${YELLOW}%s${RESET}\n" "$(printf "$MSG_DIFF_REPORT" "$DIFF_CASE_FILE")"
        cat_report "$DIFF_CASE_FILE"
    else
        echo "$MSG_TEMP_DELETED"
    fi
    exit 1
}

# ── options ──────────────────────────────────────────────────

# clean up on both Ctrl+C (INT) and kill/timeout (TERM); without the TERM
# trap a plain `kill` or `timeout` would leave the temp files behind
setup_i18n
trap cleanup INT TERM

# Accept both "--opt value" and "--opt=value" spellings by splitting the
# latter into two positional parameters before getopts runs.
PRE=()
for a in "$@"; do
    if [[ "$a" == --*=* ]]; then
        PRE+=("${a%%=*}" "${a#*=}")
    else
        PRE+=("$a")
    fi
done
set -- "${PRE[@]}"

# Snapshot the (preprocessed) positional parameters once: inside a function
# $# is the function's own argument count, so long_arg must read from this
# array (and its length) instead. Guarded by `OPTIND > ${#ARGS[@]}`
# because indexing past the end would trip `set -u`.
ARGS=("$@")

# Fetch the value for a long option from the remaining positional
# parameters; error out (exit 1) if the argument is missing.
long_arg() {
    if ((OPTIND > ${#ARGS[@]})); then
        echo "$(printf "$MSG_ERR_LONG_REQUIRES" "${OPTARG}")" >&2
        usage 1
    fi
    LONG_ARG="${ARGS[$((OPTIND - 1))]}"
    # a value that looks like an option is a missing-argument typo
    # (e.g. `--dir --infinite`): reject it like GNU getopt_long does
    if [[ "$LONG_ARG" == -* ]]; then
        echo "$(printf "$MSG_ERR_LONG_REQUIRES" "${OPTARG}")" >&2
        usage 1
    fi
    OPTIND=$((OPTIND + 1))
}

while getopts ":n:d:a:t:g:s:e:c:C:hl:O:T:N-:" opt; do
    case "$opt" in
        n) MAX_ATTEMPTS="$OPTARG" ;;
        N) INFINITE=1 ;;
        e) EPS="$OPTARG" ;;
        c) CMP_MODE="$OPTARG" ;;
        C)
            CMP_SRC="$OPTARG"
            CMP_MODE="custom"
            ;;
        d) [[ -n "$OPTARG" ]] && TMP_DIR="$OPTARG" ;;
        s) CXX_STD="$OPTARG" ;;
        a) ANS_SRC="$OPTARG" ;;
        t) TEST_SRC="$OPTARG" ;;
        g) DATA_SRC="$OPTARG" ;;
        l)
            LANG_SETTING="$OPTARG"
            setup_i18n
            ;;
        T) TIMEOUT_SEC="$OPTARG" ;;
        O) OPT_LEVEL="$OPTARG" ;;
        h) usage ;;
        -)
            case "${OPTARG}" in
                max-attempts)
                    long_arg
                    MAX_ATTEMPTS="$LONG_ARG"
                    ;;
                infinite) INFINITE=1 ;;
                dir)
                    long_arg
                    [[ -n "$LONG_ARG" ]] && TMP_DIR="$LONG_ARG"
                    ;;
                std)
                    long_arg
                    CXX_STD="$LONG_ARG"
                    ;;
                ans)
                    long_arg
                    ANS_SRC="$LONG_ARG"
                    ;;
                test)
                    long_arg
                    TEST_SRC="$LONG_ARG"
                    ;;
                gen | data)
                    long_arg
                    DATA_SRC="$LONG_ARG"
                    ;;
                O[0-3]) OPT_LEVEL="${OPTARG#O}" ;;
                eps)
                    long_arg
                    EPS="$LONG_ARG"
                    ;;
                cmp)
                    long_arg
                    CMP_MODE="$LONG_ARG"
                    ;;
                cmp-src)
                    long_arg
                    CMP_SRC="$LONG_ARG"
                    CMP_MODE="custom"
                    ;;
                lang)
                    long_arg
                    LANG_SETTING="$LONG_ARG"
                    setup_i18n
                    ;;
                timeout)
                    long_arg
                    TIMEOUT_SEC="$LONG_ARG"
                    ;;
                help) usage ;;
                *)
                    echo "$(printf "$MSG_ERR_UNKNOWN_LONG" "${OPTARG}")" >&2
                    usage 1
                    ;;
            esac
            ;;
        \?)
            # silent mode (leading ':') puts the offending letter in OPTARG
            echo "$(printf "$MSG_ERR_UNKNOWN" "${OPTARG}")" >&2
            usage 1
            ;;
        :)
            # missing argument: OPTARG carries the option letter itself
            echo "$(printf "$MSG_ERR_REQUIRES" "${OPTARG}")" >&2
            usage 1
            ;;
    esac
done
shift $((OPTIND - 1))
# the tool takes no positional arguments; anything left over is a stray
# value that was silently split off a flag-less long option
# (e.g. `--infinite=1` would otherwise run forever)
if (( $# > 0 )); then
    echo "$(printf "$MSG_ERR_UNKNOWN" "$1")" >&2
    usage 1
fi

# normalize the output directory: strip trailing slash, create if missing
TMP_DIR="${TMP_DIR%/}"
[[ -n "$TMP_DIR" ]] || TMP_DIR="/"
if ! mkdir -p "$TMP_DIR" 2>/dev/null; then
    echo "$(printf "$MSG_ERR_DIR" "$TMP_DIR")" >&2
    exit 1
fi
# recompute the intermediate paths now that -d/--dir may have changed TMP_DIR
set_temp_paths

# the diff report is named after the tested program:
#   default test.cpp → diff.txt, -t abc.cpp → diff_abc.txt
test_base="${TEST_SRC##*/}"
test_base="${test_base%.*}"
if [[ "$test_base" == "test" ]]; then
    DIFF_CASE_FILE="diff.txt"
else
    DIFF_CASE_FILE="diff_${test_base}.txt"
fi

case "$MAX_ATTEMPTS" in
    '' | *[!0-9]*)
        echo "$(printf "$MSG_ERR_ATTEMPTS" "$MAX_ATTEMPTS")" >&2
        exit 1
        ;;
esac

# float format via bash regex; a leading '-' means negative. Pure bash on
# purpose: `awk -v e=... 'BEGIN { exit !(e >= 0) }'` can return a nonzero
# exit on some setups, which wrongly rejects the valid default 1e-6.
if [[ ! "$EPS" =~ ^[+-]?([0-9]+(\.[0-9]*)?|\.[0-9]+)([eE][+-]?[0-9]+)?$ ]] || [[ "$EPS" == -* ]]; then
    echo "$(printf "$MSG_ERR_EPS" "$EPS")" >&2
    exit 1
fi
# normalize: a leading '+' is accepted by the format check but the
# comparator and the report would otherwise echo it back
EPS="${EPS#+}"

case "$CMP_MODE" in
    auto | strict | custom) ;;
    *)
        echo "$(printf "$MSG_ERR_CMP_MODE" "$CMP_MODE")" >&2
        exit 1
        ;;
esac

if [[ $CMP_MODE == "custom" && -z "$CMP_SRC" ]]; then
    echo "$MSG_ERR_CMP_SRC_REQ" >&2
    exit 1
fi

if [[ -n "$CMP_SRC" && ! -f "$CMP_SRC" ]]; then
    echo "$(printf "$MSG_ERR_CMP_SRC" "$CMP_SRC")" >&2
    exit 1
fi

case "$LANG_SETTING" in
    en | zh) ;;
    *)
        echo "$(printf "$MSG_ERR_LANG" "$LANG_SETTING")" >&2
        exit 1
        ;;
esac

case "$OPT_LEVEL" in
    0 | 1 | 2 | 3) ;;
    *)
        echo "$(printf "$MSG_ERR_OPT" "$OPT_LEVEL")" >&2
        exit 1
        ;;
esac

case "$TIMEOUT_SEC" in
    '' | *[!0-9]*)
        echo "$(printf "$MSG_ERR_TIMEOUT" "$TIMEOUT_SEC")" >&2
        exit 1
        ;;
esac

if ((TIMEOUT_SEC > 0)) && ! command -v timeout >/dev/null 2>&1; then
    echo "$MSG_WARN_NO_TIMEOUT" >&2
    TIMEOUT_SEC=0
fi

# ── python support ───────────────────────────────────────────
# Sources are dispatched by extension: .py runs through the Python
# interpreter, everything else (C/C++) is compiled with g++. Pick the
# interpreter once here (python3 preferred, python as fallback).
PYTHON_BIN=""
if [[ $DATA_SRC == *.py || $ANS_SRC == *.py || $TEST_SRC == *.py || $CMP_SRC == *.py ]]; then
    if command -v python3 >/dev/null 2>&1; then
        PYTHON_BIN="python3"
    elif command -v python >/dev/null 2>&1; then
        PYTHON_BIN="python"
    else
        echo "$MSG_ERR_NO_PYTHON" >&2
        exit 1
    fi
fi

# Runtime command per program: the compiled binary for C/C++, or
# "<interpreter> <source>" for Python. CMP_CMD is unused in strict mode.
DATA_CMD=("$OUT_DATA")
[[ $DATA_SRC == *.py ]] && DATA_CMD=("$PYTHON_BIN" "$DATA_SRC")
ANS_CMD=("$OUT_ANS")
[[ $ANS_SRC == *.py ]] && ANS_CMD=("$PYTHON_BIN" "$ANS_SRC")
TEST_CMD=("$OUT_TEST")
[[ $TEST_SRC == *.py ]] && TEST_CMD=("$PYTHON_BIN" "$TEST_SRC")
CMP_CMD=("$OUT_CMP")
[[ $CMP_MODE == "custom" && $CMP_SRC == *.py ]] && CMP_CMD=("$PYTHON_BIN" "$CMP_SRC")

# ── compilation (parallel) ───────────────────────────────────

OPT_FLAGS="-O$OPT_LEVEL"

CXXFLAGS="-std=$CXX_STD $OPT_FLAGS"
printf "  ${YELLOW}%s${RESET}\n" "$(printf "$MSG_COMPILING" "$CXXFLAGS")"

compile_one() {
    local src="$1" out="$2"
    # Runs as a background job, so it must only report failure (nonzero
    # return) and never clean up itself: the other parallel compiles may
    # still be writing their outputs. The parent kills the remaining jobs
    # and runs remove_temp_files after they are reaped.
    # Python sources are not compiled — they are run directly by the
    # interpreter, so the script only needs to exist here.
    if [[ "$src" == *.py ]]; then
        if [[ ! -f "$src" ]]; then
            printf "${RED}  ✗ %s${RESET}\n" "$(printf "$MSG_COMPILE_FAIL" "$src")" >&2
            return 1
        fi
        return 0
    fi
    if ! g++ $CXXFLAGS "$src" -o "$out"; then
        printf "${RED}  ✗ %s${RESET}\n" "$(printf "$MSG_COMPILE_FAIL" "$src")" >&2
        return 1
    fi
}

compile_cmp() {
    # inline float comparator: compiled from stdin, no extra source file
    if ! g++ $CXXFLAGS -x c++ -o "$OUT_CMP" - <<'CMP_EOF'; then
// Float-aware stress-test comparator: token-by-token
//  - if both tokens parse as numbers, compare with tolerance (|a-b| <= eps * max(1,|a|,|b|))
//  - otherwise compare strictly as strings
// usage: cmp.out <ans_file> <test_file> [eps]
#include <bits/stdc++.h>
using namespace std;

static double EPS = 1e-6;

static bool zh() {
    const char* l = getenv("DP_LANG");
    return l && strcmp(l, "zh") == 0;
}

static const char* m(const char* en, const char* zh_) {
    return zh() ? zh_ : en;
}

static bool isNum(const string& s) {
    if (s.empty()) return false;
    char* end = nullptr;
    strtod(s.c_str(), &end);
    return end == s.c_str() + s.size();
}

static double parse(const string& s) {
    return strtod(s.c_str(), nullptr);
}

static vector<pair<string, int>> readTokens(istream& in) {
    vector<pair<string, int>> v;
    string line;
    int lineNo = 0;
    while (getline(in, line)) {
        ++lineNo;
        istringstream ss(line);
        string t;
        while (ss >> t) v.emplace_back(t, lineNo);
    }
    return v;
}

int main(int argc, char** argv) {
    if (argc < 3) {
        fprintf(stderr, "%s\n",
                m("usage: cmp.out <ans_file> <test_file> [eps]",
                  "用法：cmp.out <ans_file> <test_file> [eps]"));
        return 2;
    }
    if (argc >= 4) EPS = atof(argv[3]);

    ifstream fa(argv[1]), fb(argv[2]);
    if (!fa.is_open() || !fb.is_open()) {
        fprintf(stderr, "%s\n", m("error: cannot open input files",
                                  "错误：无法打开输入文件"));
        return 2;
    }

    auto a = readTokens(fa);
    auto b = readTokens(fb);

    if (a.size() != b.size()) {
        cerr << m("token count mismatch: ", "token 数量不一致：")
             << "ans=" << a.size() << " test=" << b.size() << "\n";
        size_t n = min(a.size(), b.size()), i = 0;
        while (i < n && a[i].first == b[i].first) ++i;
        size_t lo = i >= 3 ? i - 3 : 0;
        size_t hi = min(n, i + 4);
        for (size_t j = lo; j < hi; ++j) {
            cerr << "  token " << (j + 1) << ": ans=\"" << a[j].first
                 << "\" test=\"" << b[j].first << "\"\n";
        }
        return 1;
    }

    for (size_t i = 0; i < a.size(); ++i) {
        const string& x = a[i].first;
        const string& y = b[i].first;
        if (isNum(x) && isNum(y)) {
            double dx = parse(x), dy = parse(y);
            if (isnan(dx) || isnan(dy)) {
                if (!(isnan(dx) && isnan(dy))) {
                    cerr << m("numeric mismatch (token ", "数值不一致（token ")
                         << (i + 1) << m(", line ", "，第 ")
                         << a[i].second << m("): ans=", " 行）：ans=")
                         << "\"" << x << "\" test=\"" << y << "\"\n";
                    return 1;
                }
            } else {
                double diff = fabs(dx - dy);
                double scale = max(1.0, max(fabs(dx), fabs(dy)));
                if (diff > EPS * scale) {
                    cerr << setprecision(10)
                         << m("numeric mismatch (token ", "数值不一致（token ")
                         << (i + 1) << m(", line ", "，第 ")
                         << a[i].second << m("):\n", " 行）：\n")
                         << "  ans=\"" << x << "\"\n"
                         << "  test=\"" << y << "\"\n"
                         << "  " << m("abs error=", "绝对误差=") << diff
                         << " " << m("rel error=", "相对误差=") << (diff / scale)
                         << m(" > eps=", " > 阈值=") << EPS << "\n";
                    return 1;
                }
            }
        } else if (x != y) {
            cerr << m("content mismatch (token ", "内容不一致（token ")
                 << (i + 1) << m(", ans line ", "，ans 第 ")
                 << a[i].second << m(", test line ", " 行，test 第 ")
                 << b[i].second << m("):\n", " 行）：\n")
                 << "  ans=\"" << x << "\"\n"
                 << "  test=\"" << y << "\"\n";
            return 1;
        }
    }
    return 0;
}
CMP_EOF
        printf "${RED}  ✗ %s${RESET}\n" "$MSG_COMPILE_FAIL_CMP" >&2
        # same rule as compile_one: only report, the parent cleans up
        return 1
    fi
}

# Collect PIDs and wait on each one: a bare `wait` always returns 0, which
# would silently mask a failed background compile.
compile_pids=()
compile_one "$DATA_SRC" "$OUT_DATA" &
compile_pids+=($!)
compile_one "$ANS_SRC" "$OUT_ANS" &
compile_pids+=($!)
compile_one "$TEST_SRC" "$OUT_TEST" &
compile_pids+=($!)
if [[ $CMP_MODE == "custom" ]]; then
    compile_one "$CMP_SRC" "$OUT_CMP" &
    compile_pids+=($!)
elif [[ $CMP_MODE == "auto" ]]; then
    compile_cmp &
    compile_pids+=($!)
fi

for cpid in "${compile_pids[@]}"; do
    if ! wait "$cpid"; then
        # a compile failed: kill the remaining background compiles before
        # cleaning up, otherwise they can keep writing artifacts (e.g.
        # OUT_TEST) and leave stray files after remove_temp_files ran
        for other in "${compile_pids[@]}"; do
            kill_job_tree "$other"
        done
        # reap the killed jobs (blocking until they are gone) so nothing
        # writes after the cleanup below
        wait 2>/dev/null || true
        remove_temp_files
        exit 1
    fi
done

printf "  ${GREEN}✔ %s${RESET}\n" "$MSG_COMPILE_OK"
echo ""

# ── program runner ──────────────────────────────────────────

# Run the data generator with an optional timeout; DATA_CMD holds the
# actual command (binary or python interpreter + script). stdout goes to
# $1; $2 is an optional stdin file (empty = no stdin redirect). Exit
# status lands in the global RUN_RC (124 = timed out).
run_prog() {
    local out="$1" stdin_file="$2"
    local rc=0
    local -a cmd=("${DATA_CMD[@]}")
    if ((TIMEOUT_SEC > 0)); then
        # GNU timeout (Linux) supports -k: kill hard after a grace period
        # so a SIGTERM-ignoring program cannot hang the run forever
        if [[ $PLATFORM == "linux" ]]; then
            cmd=(timeout -k 5 "$TIMEOUT_SEC" "${cmd[@]}")
        else
            cmd=(timeout "$TIMEOUT_SEC" "${cmd[@]}")
        fi
    fi
    # launch as a background job and wait, so cleanup()'s `jobs -p` sees
    # the running child and can kill it on INT/TERM (a plain foreground
    # run would be orphaned past the signal)
    if [[ -n "$stdin_file" ]]; then
        "${cmd[@]}" <"$stdin_file" >"$out" &
    else
        "${cmd[@]}" >"$out" &
    fi
    local pid=$!
    wait "$pid" || rc=$?
    RUN_RC=$rc
}

# Report a crash/timeout for $1 based on the exit code (defaults to the
# global RUN_RC), then abort the script.
die_on_run_failure() {
    local exe="$1" rc="${2:-$RUN_RC}" stage="${3:-unknown}"
    local exe_disp="${exe##*/}" # strip the /tmp dir in error messages
    local msg
    if ((rc == 124)); then
        msg="$(printf "$MSG_TIMEOUT" "$exe_disp" "$TIMEOUT_SEC")"
    else
        msg="$(printf "$MSG_CRASHED" "$exe_disp")"
    fi
    # 进度条还停在当前行（RE 都发生在 draw_bar 之前）：先清行再换行，
    # 错误信息和盒子从新的一行开始，避免与进度条挤在同一行
    [[ -t 1 ]] && printf "\033[2K\r\n"
    printf "${RED}  ✗ %s${RESET}\n" "$msg"
    # a runtime error is a counterexample too: write a diff report that
    # embeds the offending input (and whatever output exists) so the case
    # can be reproduced; the report file is always kept
    box_line "$RED" "$BOLD" "$(printf "$MSG_RE_FOUND")  $(printf "$MSG_ATTEMPT" "$count")"
    write_diff_report "$count" "" "re" "$msg" "$stage"
    remove_temp_files
    echo ""
    printf "  ${BOLD}${YELLOW}%s${RESET}\n" "$(printf "$MSG_DIFF_REPORT" "$DIFF_CASE_FILE")"
    cat_report "$DIFF_CASE_FILE"
    exit 1
}

# Wall-clock nanosecond timestamp. bash >= 5 reads $EPOCHREALTIME without
# forking a process (fast path, no date dependency); older bash falls back
# to GNU date (Linux/Git Bash) or whole seconds elsewhere.
now_ns() {
    if ((BASH_VERSINFO[0] >= 5)); then
        local t="$EPOCHREALTIME" s ns
        s="${t%%.*}"
        ns="${t#*.}"
        ns="${ns:0:9}"
        # EPOCHREALTIME has microsecond precision (6 fractional digits);
        # right-pad with zeros to nanoseconds. Never format the fractional
        # part with %09d: a leading zero makes bash parse it as octal
        # ("invalid octal number") and corrupts the value.
        while (( ${#ns} < 9 )); do ns="${ns}0"; done
        printf '%s%s\n' "$s" "$ns"
    else
        date +%s%N 2>/dev/null || date +%s000000000
    fi
}

# Run ans and test serially: both only read DATA_FILE and write their own
# output file, so they never clash. Running one after the other gives each
# program the CPU to itself, so the wall-clock timings are exact and never
# interfere with each other (concurrent runs shared CPU time and skewed the
# slower program's reading on single-core machines). Crashes/timeouts abort
# the script.
run_pair() {
    local ra=0 rb=0

    # ans first: run, time, then fail fast on crash/timeout
    local -a ca=("${ANS_CMD[@]}")
    if ((TIMEOUT_SEC > 0)); then
        if [[ $PLATFORM == "linux" ]]; then
            ca=(timeout -k 5 "$TIMEOUT_SEC" "${ca[@]}")
        else
            ca=(timeout "$TIMEOUT_SEC" "${ca[@]}")
        fi
    fi
    local t0=$(now_ns)
    "${ca[@]}" <"$DATA_FILE" >"$ANS_FILE" &
    local pa=$!
    wait "$pa" || ra=$?
    LAST_ANS_NS=$(( $(now_ns) - t0 ))
    ANS_TOTAL_NS=$((ANS_TOTAL_NS + LAST_ANS_NS))
    if ((ANS_MIN_NS == 0 || LAST_ANS_NS < ANS_MIN_NS)); then ANS_MIN_NS=$LAST_ANS_NS; fi
    ((LAST_ANS_NS > ANS_MAX_NS)) && ANS_MAX_NS=$LAST_ANS_NS
    ((ra == 0)) || die_on_run_failure "$ANS_SRC" "$ra" "ans"

    # then test, same drill
    local -a cb=("${TEST_CMD[@]}")
    if ((TIMEOUT_SEC > 0)); then
        if [[ $PLATFORM == "linux" ]]; then
            cb=(timeout -k 5 "$TIMEOUT_SEC" "${cb[@]}")
        else
            cb=(timeout "$TIMEOUT_SEC" "${cb[@]}")
        fi
    fi
    local t1=$(now_ns)
    "${cb[@]}" <"$DATA_FILE" >"$TEST_FILE" &
    local pb=$!
    wait "$pb" || rb=$?
    LAST_TEST_NS=$(( $(now_ns) - t1 ))
    TEST_TOTAL_NS=$((TEST_TOTAL_NS + LAST_TEST_NS))
    if ((TEST_MIN_NS == 0 || LAST_TEST_NS < TEST_MIN_NS)); then TEST_MIN_NS=$LAST_TEST_NS; fi
    ((LAST_TEST_NS > TEST_MAX_NS)) && TEST_MAX_NS=$LAST_TEST_NS
    ((rb == 0)) || die_on_run_failure "$TEST_SRC" "$rb" "test"
}

# ── progress bar ─────────────────────────────────────────────

BAR_WIDTH=24

draw_bar() {
    local current=$1 total=$2
    local pct filled bar

    # keep piped/redirected logs clean: no progress-bar escape noise;
    # return 0 so the loop's status stays clean under `set -e`
    [[ -t 1 ]] || return 0

    if ((total <= 0)); then
        # infinite mode: no total, show only the running count
        printf "\033[2K\r  ${CYAN}%s${RESET}  %d" "$MSG_RUN" "$current"
        return
    fi

    pct=$((current * 100 / total))
    filled=$((current * BAR_WIDTH / total))

    printf -v bar '%*s' "$filled" ''
    bar="${bar// /█}"
    printf -v bar '%s%*s' "$bar" $((BAR_WIDTH - filled)) ''
    bar="${bar// /░}"

    printf "\033[2K\r  ${CYAN}%s${RESET}  [${CYAN}%s${RESET}]  %3d/%-3d  (%3d%%)" "$MSG_RUN" "$bar" "$current" "$total" "$pct"
}

# ── main loop ────────────────────────────────────────────────

line="M=$([ $INFINITE -eq 1 ] && echo '∞' || echo $MAX_ATTEMPTS)  O=$OPT_FLAGS  T=$TIMEOUT_SEC"
box_line "$CYAN" "" "$line"
printf "  ${YELLOW}%s${RESET}\n" "$MSG_PRESS_CTRL_C"
echo ""

count=0
found=0
ANS_TOTAL_NS=0
TEST_TOTAL_NS=0
ANS_MIN_NS=0
ANS_MAX_NS=0
TEST_MIN_NS=0
TEST_MAX_NS=0
LAST_ANS_NS=0
LAST_TEST_NS=0

while ((INFINITE)) || ((count < MAX_ATTEMPTS)); do
    ((++count))

    # generate
    run_prog "$DATA_FILE" ""
    ((RUN_RC == 0)) || die_on_run_failure "$DATA_SRC" "$RUN_RC" "data"

    # run ans & test serially
    run_pair

    # compare: auto mode uses the float comparator, strict mode uses byte-level cmp
    cmp_detail=""
    if [[ $CMP_MODE == "strict" ]]; then
        if ! cmp -s "$ANS_FILE" "$TEST_FILE"; then
            found=1
        fi
    elif [[ $CMP_MODE == "custom" ]]; then
        # custom comparator: <input> <ans> <test>, exit 0 = match; its
        # stderr (captured as cmp_detail) is shown in the report
        if ! cmp_detail="$(DP_LANG="$LANG_SETTING" "${CMP_CMD[@]}" "$DATA_FILE" "$ANS_FILE" "$TEST_FILE" 2>&1)"; then
            found=1
        fi
    else
        if ! cmp_detail="$(DP_LANG="$LANG_SETTING" "${CMP_CMD[@]}" "$ANS_FILE" "$TEST_FILE" "$EPS" 2>&1)"; then
            found=1
        fi
    fi

    if ((found)); then
        # draw_bar 不换行，进度条还停在当前行：先清掉该行再换行，
        # 反例盒子才能从新的一行、行首开始绘制
        [[ -t 1 ]] && printf "\033[2K\r\n"
        box_line "$RED" "$BOLD" "$(printf "$MSG_CE_FOUND")  $(printf "$MSG_ATTEMPT" "$count")"
        # write the full report (input/expected/got/comparator); it is
        # shown on the terminal in the teardown section below
        write_diff_report "$count" "$cmp_detail"
        break
    fi

    if ((INFINITE)); then
        draw_bar "$count" 0
    else
        draw_bar "$count" "$MAX_ATTEMPTS"
    fi
done

# 结束前的统一空行：found 分支已在盒子前自行清行换行，这里只负责
# 正常跑满时给进度条补一个换行，并作为盒子与后续输出的间隔
echo ""

# ── teardown ─────────────────────────────────────────────────

remove_temp_files

if ((found)); then
    # the report is always kept and always shown on the terminal
    printf "  ${BOLD}${YELLOW}%s${RESET}\n" "$(printf "$MSG_DIFF_REPORT" "$DIFF_CASE_FILE")"
    cat_report "$DIFF_CASE_FILE"
    # a counterexample means the test FAILED: exit nonzero so scripts and
    # CI can distinguish it from a clean pass (runtime errors already do)
    exit 1
else
    if ((count > 0)); then
        ans_avg_ms="$(awk -v t="$ANS_TOTAL_NS" -v n="$count" 'BEGIN { printf "%.3f", t / n / 1e6 }')"
        test_avg_ms="$(awk -v t="$TEST_TOTAL_NS" -v n="$count" 'BEGIN { printf "%.3f", t / n / 1e6 }')"
        ans_min_ms="$(awk -v t="$ANS_MIN_NS" 'BEGIN { printf "%.3f", t / 1e6 }')"
        ans_max_ms="$(awk -v t="$ANS_MAX_NS" 'BEGIN { printf "%.3f", t / 1e6 }')"
        test_min_ms="$(awk -v t="$TEST_MIN_NS" 'BEGIN { printf "%.3f", t / 1e6 }')"
        test_max_ms="$(awk -v t="$TEST_MAX_NS" 'BEGIN { printf "%.3f", t / 1e6 }')"
        box_block "$GREEN" \
            "$(printf "$MSG_ALL_PASSED" "$MAX_ATTEMPTS")" \
            "$(printf '%s: %s    %s: %s' "$MSG_CMP_MODE" "$CMP_MODE" "$MSG_EPS" "$EPS")" \
            "$(printf '%s: %s' "$MSG_COMPILE_FLAGS" "$CXXFLAGS")" \
            "$(printf "$MSG_AVG_TIME" "$ans_avg_ms" "$test_avg_ms")" \
            "$(printf '%s: ans [%s, %s]  test [%s, %s] ms' "$MSG_RANGE" "$ans_min_ms" "$ans_max_ms" "$test_min_ms" "$test_max_ms")"
    else
        box_line "$GREEN" "" "$(printf "$MSG_ALL_PASSED" "$MAX_ATTEMPTS")"
    fi
fi
