#!/usr/bin/env bash
# bench_dp.sh — 验证 dp 交替计时的公平性
#
# 原理：同一个文件同时当 ans 和 test，跑多组 dp，每组取一行
#       "Avg time per attempt (ms): ans=... test=..."，算差值。
#       若交替计时公平，差值应围绕 0 随机波动（有正有负）；
#       若稳定偏向一边，说明还有残余的系统性不对称。
#
# 用法:
#   ./bench_dp.sh                 # 默认 10 组 × 每组 10 轮, 源文件 K.cpp
#   ./bench_dp.sh 15 20 K.cpp     # 15 组 × 20 轮, 用 K.cpp
#   DP=./dp ./bench_dp.sh         # 指定 dp 脚本路径
set -euo pipefail

GROUPS=${1:-10}          # 跑多少组（每次调用 dp 是一个独立样本）
ROUNDS=${2:-10}          # 每组内部 dp -n 的轮数
SRC=${3:-K.cpp}          # 对拍源文件（ans 和 test 用同一个）
DP_CMD=${DP:-dp}

echo "== bench_dp =="
echo "groups=$GROUPS  rounds/group=$ROUNDS  src=$SRC  dp=$DP_CMD"
echo ""

pos=0; neg=0; zero=0     # 差值方向计数（阈值 ±0.01ms 视为 ~0）
DIFFS=()

for ((i = 1; i <= GROUPS; i++)); do
    # 跑一组 dp；用 || true 兜底，避免编译失败中断整个循环
    out="$("$DP_CMD" -k -t "$SRC" -n "$ROUNDS" -a "$SRC" 2>&1 || true)"
    line="$(grep 'Avg time per attempt' <<< "$out" || true)"
    if [[ -z "$line" ]]; then
        echo "  group $i: 没有抓到计时行（dp 编译失败？）"
        continue
    fi

    ans="$(sed -n 's/.*ans=\([0-9.]*\).*/\1/p' <<< "$line")"
    tst="$(sed -n 's/.*test=\([0-9.]*\).*/\1/p' <<< "$line")"
    d="$(awk -v a="$ans" -v t="$tst" 'BEGIN { printf "%.3f", a - t }')"
    DIFFS+=("$d")

    sign="$(awk -v d="$d" 'BEGIN { if (d > 0.01) print "pos"; else if (d < -0.01) print "neg"; else print "zero" }')"
    case "$sign" in
        pos)  ((++pos)) ;;
        neg)  ((++neg)) ;;
        *)    ((++zero)) ;;
    esac

    printf "  group %2d: ans=%-8s test=%-8s diff=%+0.3f ms\n" "$i" "$ans" "$tst" "$d"
done

n="${#DIFFS[@]}"
echo ""
if ((n == 0)); then
    echo "没有收集到数据"
    exit 1
fi

# 汇总统计
printf '%s\n' "${DIFFS[@]}" | awk -v n="$n" -v p="$pos" -v q="$neg" -v z="$zero" '
BEGIN { s = 0; a = 0; max = -1e9; min = 1e9 }
{
    s += $1                 # 差值代数和
    a += ($1 < 0 ? -$1 : $1) # 差值绝对值之和
    if ($1 > max) max = $1  # 最大正向差值
    if ($1 < min) min = $1  # 最小（最负）差值
}
END {
    printf "  样本数:        %d\n", n;
    printf "  diff 均值:    %+0.3f ms\n", s / n;
    printf "  |diff| 均值:  %.3f ms\n", a / n;
    printf "  方向分布:     %d 正 / %d 负 / %d 近零\n", p, q, z;
    printf "  差值范围:     [%+0.3f, %+0.3f] ms\n", min, max;
}
'

# 结论判断
dmean="$(printf '%s\n' "${DIFFS[@]}" | awk '{ s += $1 } END { printf "%.3f", s / NR }')"
awk -v d="$dmean" 'BEGIN {
    if (d > -0.2 && d < 0.2)
        print "结论: 差值围绕 0 波动（残余为噪声），计时已公平。";
    else if (d > 0)
        print "结论: ans 平均仍偏大 " d " ms —— 可能有残余不对称。";
    else
        print "结论: test 平均偏大 " (-d) " ms —— 可能有残余不对称。";
}'
