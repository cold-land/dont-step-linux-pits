#!/bin/bash
# 安装NVIDIA官方驱动并启用Wayland

# 引入通用工具函数
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/utils.sh"

# 初始化目录
init_dirs

log_info "=========================================="
log_info "开始安装NVIDIA官方驱动"
log_info "=========================================="

# 获取当前用户
CURRENT_USER=$(whoami)
log_info "当前用户: $CURRENT_USER"

# 1. 检查是否为NVIDIA显卡
log_info "检测显卡类型..."
if ! lspci | grep -i nvidia > /dev/null 2>&1; then
    log_error "未检测到NVIDIA显卡"
    log_error "本脚本仅适用于NVIDIA显卡"
    exit 1
fi

GPU_INFO=$(lspci | grep -i nvidia)
log_info "检测到NVIDIA显卡: $GPU_INFO"

# 2. 安装依赖（必须先安装kernel headers）
log_info "安装依赖包..."
PACKAGES=(
    "linux-headers-$(uname -r)"
    "build-essential"
    "dkms"
    "libglvnd-dev"
    "pkg-config"
)

for package in "${PACKAGES[@]}"; do
    if dpkg -l | grep -q "^ii  $package"; then
        log_info "$package 已安装，跳过"
    else
        log_info "安装 $package..."
        sudo apt install -y "$package"
        if [ $? -eq 0 ]; then
            log_info "成功安装 $package"
        else
            log_error "安装 $package 失败"
            exit 1
        fi
    fi
done

# 3. 安装NVIDIA驱动
log_info "安装NVIDIA驱动..."
NVIDIA_PACKAGES=(
    "nvidia-kernel-dkms"
    "nvidia-driver"
    "firmware-misc-nonfree"
)

for package in "${NVIDIA_PACKAGES[@]}"; do
    if dpkg -l | grep -q "^ii  $package"; then
        log_info "$package 已安装，跳过"
    else
        log_info "安装 $package..."
        sudo apt install -y "$package"
        if [ $? -eq 0 ]; then
            log_info "成功安装 $package"
        else
            log_error "安装 $package 失败"
            exit 1
        fi
    fi
done

# 4. 启用Kernel Modesetting（用于Wayland）
log_info "启用Kernel Modesetting..."
GRUB_FILE="/etc/default/grub.d/nvidia-modeset.cfg"
if [ -f "$GRUB_FILE" ]; then
    backup_file "$GRUB_FILE"
fi

echo 'GRUB_CMDLINE_LINUX="$GRUB_CMDLINE_LINUX nvidia-drm.modeset=1 nvidia-drm.fbdev=1"' | sudo tee "$GRUB_FILE" > /dev/null
log_info "已创建GRUB配置文件"

sudo update-grub
if [ $? -eq 0 ]; then
    log_info "成功更新GRUB配置"
else
    log_warn "更新GRUB配置失败"
fi

# 5. 安装nvidia-suspend-common
log_info "安装nvidia-suspend-common..."
if dpkg -l | grep -q "^ii  nvidia-suspend-common"; then
    log_info "nvidia-suspend-common 已安装，跳过"
else
    sudo apt install -y nvidia-suspend-common
    if [ $? -eq 0 ]; then
        log_info "成功安装 nvidia-suspend-common"
        
        # 启用相关服务
        log_info "启用nvidia-suspend服务..."
        sudo systemctl enable nvidia-suspend.service
        sudo systemctl enable nvidia-hibernate.service
        sudo systemctl enable nvidia-resume.service
        log_info "已启用nvidia-suspend相关服务"
    else
        log_warn "安装 nvidia-suspend-common 失败"
    fi
fi

# 6. 安装多媒体相关包
log_info "安装多媒体相关包..."
MULTIMEDIA_PACKAGES=(
    "mesa-utils"
    "nvidia-vaapi-driver"
    "vainfo"
    "libva-dev"
)

for package in "${MULTIMEDIA_PACKAGES[@]}"; do
    if dpkg -l | grep -q "^ii  $package"; then
        log_info "$package 已安装，跳过"
    else
        log_info "安装 $package..."
        sudo apt install -y "$package"
        if [ $? -eq 0 ]; then
            log_info "成功安装 $package"
        else
            log_warn "安装 $package 失败"
        fi
    fi
done

# 询问是否安装MPV
echo ""
echo "=========================================="
echo "Wayland下视频播放问题"
echo "=========================================="
echo "GNOME Videos在Wayland下可能无法正常播放视频。"
echo "建议安装MPV播放器，它原生支持Wayland。"
echo ""
read -p "是否安装MPV并设置为默认播放器？[Y/n]: " install_mpv

if [[ ! "$install_mpv" =~ ^[Nn]$ ]]; then
    log_info "安装MPV播放器..."
    sudo apt install -y mpv
    if [ $? -eq 0 ]; then
        log_info "成功安装MPV"
        
        # 设置MPV为默认播放器
        log_info "设置MPV为默认播放器..."
        xdg-mime default mpv.desktop video/mp4
        xdg-mime default mpv.desktop video/mpeg
        xdg-mime default mpv.desktop video/webm
        xdg-mime default mpv.desktop video/x-matroska
        xdg-mime default mpv.desktop video/quicktime
        log_info "已设置MPV为默认播放器"
        
        echo ""
        echo "=========================================="
        echo "MPV已安装并设置为默认播放器"
        echo "=========================================="
        echo "提示："
        echo "- MPV原生支持Wayland，无需额外配置"
        echo "- 使用命令: mpv 视频文件.mp4"
        echo "- 右键视频文件可以选择用其他播放器打开"
        echo ""
    else
        log_warn "安装MPV失败"
    fi
else
    log_info "用户选择不安装MPV"
fi

# 7. 配置PreserveVideoMemoryAllocations
log_info "配置PreserveVideoMemoryAllocations..."

# 检查是否已存在配置文件
if [ -f /etc/modprobe.d/nvidia-power-management.conf ]; then
    log_info "配置文件已存在，检查内容..."
    if grep -q "NVreg_PreserveVideoMemoryAllocations=1" /etc/modprobe.d/nvidia-power-management.conf; then
        log_info "配置已正确，无需修改"
    else
        log_info "配置文件存在但内容不正确，重新创建..."
        backup_file "/etc/modprobe.d/nvidia-power-management.conf"
    fi
fi

# 创建或更新配置文件
log_info "创建配置文件 /etc/modprobe.d/nvidia-power-management.conf..."
echo 'options nvidia NVreg_PreserveVideoMemoryAllocations=1' | sudo tee /etc/modprobe.d/nvidia-power-management.conf > /dev/null

if [ $? -eq 0 ]; then
    log_info "成功创建配置文件"
else
    log_warn "创建配置文件失败"
fi

# 显示当前值（如果可用）
if [ -f /proc/driver/nvidia/params ]; then
    PVA=$(cat /proc/driver/nvidia/params | grep PreserveVideoMemoryAllocations | awk '{print $2}')
    log_info "当前PreserveVideoMemoryAllocations值: $PVA (重启后生效)"
else
    log_info "驱动未加载，无法读取当前值（重启后生效）"
fi

# 完成
log_info "=========================================="
log_info "安装完成！"
log_info "=========================================="
echo ""
echo "⚠️  重要提示："
echo "1. 请立即重启系统"
echo "2. 重启后在登录界面选择 'Wayland' 会话"
echo "3. 重启后运行以下命令验证驱动："
echo "   nvidia-smi"
echo ""
echo "如果遇到问题："
echo "- 如果系统无法启动（黑屏），请在GRUB菜单中选择高级选项"
echo "- 使用之前的内核启动"
echo "- 查看日志: ${LOG_DIR}/fix.log"
echo ""
echo "日志: ${LOG_DIR}/fix.log"

read -p "是否现在重启系统？[Y/n]: " reboot_choice

if [[ "$reboot_choice" =~ ^[Nn]$ ]]; then
    echo ""
    echo "您选择不立即重启，请稍后手动重启系统。"
else
    echo ""
    echo "系统将在5秒后重启..."
    sleep 5
    sudo reboot
    if [ $? -ne 0 ]; then
        echo ""
        echo "⚠️  自动重启失败，请手动重启系统"
        echo "运行命令: sudo reboot"
    fi
fi