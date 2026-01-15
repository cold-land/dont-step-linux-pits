#!/bin/bash
# 修复 Chrome/Edge 在 Wayland 下的视频播放问题

# 引入通用工具函数
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/utils.sh"

# 初始化目录
init_dirs

log_info "=========================================="
log_info "Chrome/Edge Wayland 视频播放问题修复"
log_info "=========================================="
log_info ""
log_info "此脚本会为 Chrome 和 Edge 添加启动参数："
log_info "  --disable-gpu-memory-buffer-video-frames"
log_info ""
log_info "这个参数只禁用 GPU 内存缓冲的视频帧，"
log_info "不会完全禁用 GPU 加速，既能解决播放问题，"
log_info "又不会影响整体性能。"
log_info ""
log_info "=========================================="
log_info ""

# 检测 Chrome
CHROME_DESKTOP="/usr/share/applications/google-chrome.desktop"
CHROME_INSTALLED=0
CHROME_TYPE=""

if dpkg -l | grep -q "google-chrome-stable"; then
    CHROME_INSTALLED=1
    CHROME_TYPE="apt"
    log_info "✓ 检测到 Chrome (APT 安装)"
elif flatpak list | grep -q "com.google.Chrome"; then
    CHROME_INSTALLED=1
    CHROME_TYPE="flatpak"
    log_info "✓ 检测到 Chrome (Flatpak 安装)"
else
    log_info "○ 未检测到 Chrome"
fi

# 检测 Edge
EDGE_DESKTOP="/usr/share/applications/microsoft-edge.desktop"
EDGE_INSTALLED=0
EDGE_TYPE=""

if dpkg -l | grep -q "microsoft-edge-stable"; then
    EDGE_INSTALLED=1
    EDGE_TYPE="apt"
    log_info "✓ 检测到 Edge (APT 安装)"
elif flatpak list | grep -q "com.microsoft.Edge"; then
    EDGE_INSTALLED=1
    EDGE_TYPE="flatpak"
    log_info "✓ 检测到 Edge (Flatpak 安装)"
else
    log_info "○ 未检测到 Edge"
fi

if [[ $CHROME_INSTALLED -eq 0 && $EDGE_INSTALLED -eq 0 ]]; then
    log_warn "未检测到 Chrome 或 Edge 浏览器"
    exit 0
fi

# 只提示已安装浏览器的禁用硬件解码信息
log_info ""
log_info "注意：如果视频仍然偏色，需手动禁用硬件解码"
if [[ $CHROME_INSTALLED -eq 1 ]]; then
    log_info "Chrome: 在地址栏输入 chrome://flags，搜索 decode，禁用 Hardware-accelerated video decode"
fi
if [[ $EDGE_INSTALLED -eq 1 ]]; then
    log_info "Edge: 在地址栏输入 edge://flags，搜索 decode，禁用 Hardware-accelerated video decode"
fi
log_info ""
log_info "=========================================="
log_info ""

# 修复 Chrome (APT 安装)
if [[ $CHROME_INSTALLED -eq 1 && $CHROME_TYPE == "apt" ]]; then
    if [ -f "$CHROME_DESKTOP" ]; then
        log_info "修复 Chrome (APT 安装)..."
        
        # 备份原文件
        backup_file "$CHROME_DESKTOP"
        
        # 修改主启动命令
        sudo sed -i 's|^Exec=/usr/bin/google-chrome-stable %U$|Exec=/usr/bin/google-chrome-stable --disable-gpu-memory-buffer-video-frames %U|g' "$CHROME_DESKTOP"
        
        # 修改新建窗口命令
        sudo sed -i 's|^Exec=/usr/bin/google-chrome-stable$|Exec=/usr/bin/google-chrome-stable --disable-gpu-memory-buffer-video-frames|g' "$CHROME_DESKTOP"
        
        log_info "✓ Chrome 修复完成"
    else
        log_warn "✗ Chrome desktop 文件不存在: $CHROME_DESKTOP"
    fi
fi

# 修复 Chrome (Flatpak 安装)
if [[ $CHROME_INSTALLED -eq 1 && $CHROME_TYPE == "flatpak" ]]; then
    log_info "Chrome (Flatpak 安装) 需要手动修改："
    log_info "  1. 找到 Flatpak Chrome 的 desktop 文件"
    log_info "  2. 添加参数: --disable-gpu-memory-buffer-video-frames"
    log_info "  3. 文件位置: ~/.local/share/applications/com.google.Chrome.desktop"
    log_info "     或 /var/lib/flatpak/exports/share/applications/com.google.Chrome.desktop"
fi

# 修复 Edge (APT 安装)
if [[ $EDGE_INSTALLED -eq 1 && $EDGE_TYPE == "apt" ]]; then
    if [ -f "$EDGE_DESKTOP" ]; then
        log_info "修复 Edge (APT 安装)..."
        
        # 备份原文件
        backup_file "$EDGE_DESKTOP"
        
        # 修改主启动命令
        sudo sed -i 's|^Exec=/usr/bin/microsoft-edge-stable %U$|Exec=/usr/bin/microsoft-edge-stable --disable-gpu-memory-buffer-video-frames %U|g' "$EDGE_DESKTOP"
        
        # 修改新建窗口命令
        sudo sed -i 's|^Exec=/usr/bin/microsoft-edge-stable$|Exec=/usr/bin/microsoft-edge-stable --disable-gpu-memory-buffer-video-frames|g' "$EDGE_DESKTOP"
        
        # 修改新建 InPrivate 窗口命令
        sudo sed -i 's|^Exec=/usr/bin/microsoft-edge-stable --inprivate$|Exec=/usr/bin/microsoft-edge-stable --inprivate --disable-gpu-memory-buffer-video-frames|g' "$EDGE_DESKTOP"
        
        log_info "✓ Edge 修复完成"
    else
        log_warn "✗ Edge desktop 文件不存在: $EDGE_DESKTOP"
    fi
fi

# 修复 Edge (Flatpak 安装)
if [[ $EDGE_INSTALLED -eq 1 && $EDGE_TYPE == "flatpak" ]]; then
    log_info "Edge (Flatpak 安装) 需要手动修改："
    log_info "  1. 找到 Flatpak Edge 的 desktop 文件"
    log_info "  2. 添加参数: --disable-gpu-memory-buffer-video-frames"
    log_info "  3. 文件位置: ~/.local/share/applications/com.microsoft.Edge.desktop"
    log_info "     或 /var/lib/flatpak/exports/share/applications/com.microsoft.Edge.desktop"
fi

log_info ""
log_info "=========================================="
log_info "修复完成！"
log_info "=========================================="
log_info ""
log_info "后续操作："
log_info "1. 重新启动 Chrome/Edge"
log_info "2. 打开 B 站或其他视频网站"
log_info "3. 测试视频播放是否正常"
log_info ""
log_info "如果视频仍然偏色，需手动禁用硬件解码："
if [[ $CHROME_INSTALLED -eq 1 ]]; then
    log_info "  Chrome: 在地址栏输入 chrome://flags，搜索 decode，禁用 Hardware-accelerated video decode"
fi
if [[ $EDGE_INSTALLED -eq 1 ]]; then
    log_info "  Edge: 在地址栏输入 edge://flags，搜索 decode，禁用 Hardware-accelerated video decode"
fi
log_info ""
log_info "如果需要恢复，可以从备份目录恢复："
if [[ $CHROME_INSTALLED -eq 1 && $CHROME_TYPE == "apt" ]]; then
    CHROME_BACKUP=$(ls -t "${BACKUP_DIR}"/*google-chrome*.backup 2>/dev/null | head -1)
    if [ -n "$CHROME_BACKUP" ]; then
        log_info "  Chrome: sudo cp $CHROME_BACKUP $CHROME_DESKTOP"
    fi
fi
if [[ $EDGE_INSTALLED -eq 1 && $EDGE_TYPE == "apt" ]]; then
    EDGE_BACKUP=$(ls -t "${BACKUP_DIR}"/*microsoft-edge*.backup 2>/dev/null | head -1)
    if [ -n "$EDGE_BACKUP" ]; then
        log_info "  Edge: sudo cp $EDGE_BACKUP $EDGE_DESKTOP"
    fi
fi
log_info ""
log_info "=========================================="