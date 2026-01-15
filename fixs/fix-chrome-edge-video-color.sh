#!/bin/bash
# 提示：解决 Chrome/Edge 在 NVIDIA 显卡上硬件解码偏色问题

# 引入通用工具函数
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/utils.sh"

# 初始化目录
init_dirs

log_info "=========================================="
log_info "Chrome/Edge 视频解码偏色问题提示"
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
log_info "问题描述"
log_info "=========================================="
log_info ""
log_info "在 NVIDIA 显卡上使用 Chrome/Edge 浏览器播放视频时，"
log_info "可能会出现 H.264 硬件解码导致的色彩偏色问题。"
log_info ""
log_info "这是 NVIDIA VA-API 驱动的已知问题，"
log_info "特别是在 Wayland 环境下。"
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
log_info "说明"
log_info "=========================================="
log_info ""
log_info "禁用硬件加速视频解码后："
log_info "- 视频将使用 CPU 软件解码"
log_info "- CPU 占用会稍高，但不会出现偏色问题"
log_info "- 不会影响 WebGL、Canvas 等其他 GPU 加速功能"
log_info ""
log_info "你的 RTX 3060 Ti 配套的 CPU 足够处理 H.264 软解码"
log_info ""

log_info "=========================================="
log_info "验证方法"
log_info "=========================================="
log_info ""
log_info "1. 打开 YouTube 播放视频"
log_info "2. 右键点击视频 -> 检查 -> 更多工具 -> 媒体"
log_info "3. 查看 Video Decoder，应该显示为软件解码"
log_info "4. 检查视频颜色是否正常"
log_info ""

log_info "=========================================="
log_info "提示完成"
log_info "=========================================="