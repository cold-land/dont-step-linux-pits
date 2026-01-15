#!/bin/bash
# 修复 Edge 浏览器视频解码偏色问题

# 引入通用工具函数
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/utils.sh"

# 初始化目录
init_dirs

log_info "=========================================="
log_info "开始修复 Edge 浏览器视频解码问题"
log_info "=========================================="

# 检查 Edge 是否已安装
if ! command -v microsoft-edge &> /dev/null && ! command -v microsoft-edge-stable &> /dev/null; then
    log_error "未找到 Microsoft Edge 浏览器"
    log_error "请先安装 Edge 浏览器"
    exit 1
fi

# 获取 Edge 命令名
EDGE_CMD="microsoft-edge"
if ! command -v microsoft-edge &> /dev/null; then
    EDGE_CMD="microsoft-edge-stable"
fi

log_info "检测到 Edge 浏览器: $EDGE_CMD"

# 获取 Edge 版本
EDGE_VERSION=$($EDGE_CMD --version)
log_info "Edge 版本: $EDGE_VERSION"

# 检查是否为 NVIDIA 显卡
if ! command -v nvidia-smi &> /dev/null; then
    log_warn "未检测到 NVIDIA 显卡"
    log_warn "此脚本主要针对 NVIDIA 显卡的 Edge 浏览器视频解码问题"
    read -p "是否继续执行？[y/N]: " continue_choice
    if [[ ! "$continue_choice" =~ ^[Yy]$ ]]; then
        log_info "用户取消执行"
        exit 0
    fi
fi

# 检查 VA-API 是否可用
if ! command -v vainfo &> /dev/null; then
    log_error "未安装 vainfo，无法检查 VA-API 状态"
    log_error "请安装 vainfo: sudo apt install vainfo"
    exit 1
fi

log_info "检查 VA-API 状态..."
VAINFO_OUTPUT=$(vainfo 2>&1)
if echo "$VAINFO_OUTPUT" | grep -q "VA-API NVDEC driver"; then
    log_info "检测到 NVIDIA VA-API 驱动正常"
else
    log_warn "未检测到 NVIDIA VA-API 驱动"
    log_warn "可能需要安装 NVIDIA 驱动"
fi

# 创建 Edge 配置目录
EDGE_CONFIG_DIR="$HOME/.config/microsoft-edge-flags.conf"
if [[ -f "$HOME/.config/microsoft-edge-flags.conf" ]]; then
    EDGE_CONFIG_DIR="$HOME/.config/microsoft-edge-flags.conf"
fi

log_info "配置 Edge 浏览器启用 VA-API 硬件解码..."

# 备份原配置文件
if [[ -f "$HOME/.config/microsoft-edge-flags.conf" ]]; then
    backup_file "$HOME/.config/microsoft-edge-flags.conf"
fi

# 创建或更新 Edge 配置文件
cat > "$HOME/.config/microsoft-edge-flags.conf" << 'EOF'
# 启用 VA-API 硬件加速视频解码
--enable-features=VaapiVideoDecoder
--enable-zero-copy
--ignore-gpu-blocklist
--enable-gpu-rasterization
--enable-native-gpu-memory-buffers
--enable-accelerated-video-decode
--enable-accelerated-video
--enable-hardware-overlays
--enable-features=UseOzonePlatform
--ozone-platform=wayland
EOF

log_info "已创建 Edge 配置文件: $HOME/.config/microsoft-edge-flags.conf"

# 创建桌面快捷方式（可选）
DESKTOP_FILE="$HOME/.local/share/applications/microsoft-edge-hwacc.desktop"
if [[ -d "$HOME/.local/share/applications" ]]; then
    log_info "创建桌面快捷方式..."

    # 获取原 desktop 文件路径
    ORIGINAL_DESKTOP=$(find /usr/share/applications -name "microsoft-edge*.desktop" 2>/dev/null | head -1)

    if [[ -n "$ORIGINAL_DESKTOP" ]]; then
        cp "$ORIGINAL_DESKTOP" "$DESKTOP_FILE"
        # 修改 Exec 行，添加 VA-API 参数
        sed -i 's|^Exec=.*|Exec=env LIBVA_DRIVERS_PATH=/usr/lib/x86_64-linux-gnu/dri LIBVA_DRIVER_NAME=nvidia /usr/bin/microsoft-edge --enable-features=VaapiVideoDecoder --enable-zero-copy --ignore-gpu-blocklist --enable-gpu-rasterization --enable-native-gpu-memory-buffers --enable-accelerated-video-decode --enable-accelerated-video --enable-hardware-overlays %U|g' "$DESKTOP_FILE"
        log_info "已创建桌面快捷方式: $DESKTOP_FILE"
    fi
fi

log_info "=========================================="
log_info "配置完成！"
log_info "=========================================="
log_info ""
log_info "请按照以下步骤操作："
log_info "1. 完全关闭 Edge 浏览器（包括后台进程）"
log_info "2. 重新打开 Edge 浏览器"
log_info "3. 在地址栏输入: edge://gpu"
log_info "4. 检查 'Video Decode' 部分，确认硬件加速已启用"
log_info "5. 测试视频播放，检查是否还有偏色问题"
log_info ""
log_info "如果问题仍然存在，请尝试："
log_info "1. 在 Edge 设置中启用 '使用硬件加速（如可用）'"
log_info "2. 重启浏览器"
log_info "3. 清除浏览器缓存"
log_info ""
log_info "注意：此配置主要针对 NVIDIA 显卡和 Wayland 会话"
log_info "如果你使用 X11，可能需要修改配置文件中的 --ozone-platform 参数"
log_info ""

echo "=========================================="
echo "配置完成！"
echo "=========================================="
echo ""
echo "请按照以下步骤操作："
echo "1. 完全关闭 Edge 浏览器（包括后台进程）"
echo "2. 重新打开 Edge 浏览器"
echo "3. 在地址栏输入: edge://gpu"
echo "4. 检查 'Video Decode' 部分，确认硬件加速已启用"
echo "5. 测试视频播放，检查是否还有偏色问题"
echo ""
echo "如果问题仍然存在，请尝试："
echo "1. 在 Edge 设置中启用 '使用硬件加速（如可用）'"
echo "2. 重启浏览器"
echo "3. 清除浏览器缓存"
echo ""
echo "注意：此配置主要针对 NVIDIA 显卡和 Wayland 会话"
echo "如果你使用 X11，可能需要修改配置文件"
echo ""