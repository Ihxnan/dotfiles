#!/bin/bash

# CPU监控（红色）
cpu_usage=$(mpstat 1 1 | awk '/Average/ {print 100 - $12}' | awk '{printf "%.1f", $0}')
cpu_icon=""
cpu_color="#FF5252"  # 红色

# 内存监控（蓝色）
mem_total=$(free -h | awk '/Mem:/ {print $2}')
mem_used=$(free -h | awk '/Mem:/ {print $3}')
mem_usage=$(free | awk '/Mem:/ {printf "%.1f", $3/$2*100}')
mem_icon=""
mem_color="#40C4FF"  # 亮蓝色

# GPU监控（绿色）
gpu_usage=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | awk '{printf "%.1f", $0}')
gpu_icon=""
gpu_color="#69F0AE"  # 绿色

# 按i3blocks原生格式输出（文本|颜色），用空格分隔各组件
echo "${cpu_icon} ${cpu_usage}%  ${mem_icon} ${mem_used}/${mem_total}(${mem_usage}%)  ${gpu_icon} ${gpu_usage}%"
echo "${cpu_color}|${mem_color}|${gpu_color}"  # 分别指定各组件颜色（用|分隔）
