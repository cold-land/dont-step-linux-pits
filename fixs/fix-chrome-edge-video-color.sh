#!/bin/bash
# 提示：解决 Chrome/Edge 在 NVIDIA 显卡上硬件解码偏色问题

# 引入通用工具函数
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/utils.sh"

# 初始化目录
init_dirs

log_info "=========================================="
log_info "Chrome/Edge 视频解码偏色问题解决方案"
log_info "=========================================="

# 检测显卡
if command -v nvidia-smi &> /dev/null; then
    GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null)
    log_info "检测到 NVIDIA 显卡: $GPU_NAME"
else
    log_warn "未检测到 NVIDIA 显卡"
    log_info "此提示主要针对 NVIDIA 显卡用户"
fi

# 检测浏览器
HAS_CHROME=0
HAS_EDGE=0

if command -v google-chrome &> /dev/null || command -v google-chrome-stable &> /dev/null; then
    HAS_CHROME=1
    log_info "检测到 Chrome 浏览器"
fi

if command -v microsoft-edge &> /dev/null || command -v microsoft-edge-stable &> /dev/null; then
    HAS_EDGE=1
    log_info "检测到 Edge 浏览器"
fi

if [[ $HAS_CHROME -eq 0 && $HAS_EDGE -eq 0 ]]; then
    log_warn "未检测到 Chrome 或 Edge 浏览器"
    exit 0
fi

log_info ""
log_info "=========================================="
log_info "解决方法"
log_info "=========================================="
log_info ""

if [[ $HAS_CHROME -eq 1 ]]; then
    log_info "Chrome 浏览器："
    log_info "1. 在地址栏输入: chrome://flags"
    log_info "2. 搜索: decode"
    log_info "3. 找到 'Hardware-accelerated video decode'"
    log_info "4. 设置为: Disabled"
    log_info "5. 点击底部的 Relaunch 重启浏览器"
    log_info ""
fi

if [[ $HAS_EDGE -eq 1 ]]; then
    log_info "Edge 浏览器："
    log_info "1. 在地址栏输入: edge://flags"
    log_info "2. 搜索: decode"
    log_info "3. 找到 'Hardware-accelerated video decode'"
    log_info "4. 设置为: Disabled"
    log_info "5. 点击底部的 Relaunch 重启浏览器"
    log_info ""
fi

log_info "=========================================="
log_info "提示完成"
log_info "=========================================="