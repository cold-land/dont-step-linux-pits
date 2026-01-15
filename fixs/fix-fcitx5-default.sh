#!/bin/bash
# 配置fcitx5为默认输入法并安装必要的GNOME扩展

# 捕获 Ctrl+C 信号，防止误操作
trap 'echo ""; echo "警告：检测到中断信号 (Ctrl+C)"; echo "请按 Ctrl+Shift+C 复制文本，不要按 Ctrl+C"; echo "按回车键继续或按 Ctrl+C 退出..."; read' SIGINT

# 引入通用工具函数
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/utils.sh"

# 初始化目录
init_dirs

log_info "=========================================="
log_info "开始配置fcitx5输入法"
log_info "=========================================="

# 获取当前用户
CURRENT_USER=$(whoami)
log_info "当前用户: $CURRENT_USER"

# 检查fcitx5是否安装
if ! command_exists fcitx5; then
    log_error "未找到 fcitx5 命令"
    log_error "请先安装 fcitx5 包"
    exit 1
fi

# 检查im-config是否安装
if ! command_exists im-config; then
    log_error "未找到 im-config 命令"
    log_error "请先安装 im-config 包"
    exit 1
fi

# 检查当前会话类型
XDG_SESSION_TYPE=$(echo $XDG_SESSION_TYPE)
log_info "当前会话类型: $XDG_SESSION_TYPE"

if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
    log_warn "检测到Wayland会话"
    log_warn "fcitx5在Wayland下需要安装GNOME扩展才能正常工作"
fi

# 1. 设置fcitx5为默认输入法
log_info "设置fcitx5为默认输入法..."
im-config -n fcitx5
if [ $? -eq 0 ]; then
    log_info "成功设置fcitx5为默认输入法"
else
    log_warn "设置fcitx5为默认输入法失败"
fi

# 2. 安装必要的包
log_info "安装必要的包..."

PACKAGES=(
    "gnome-shell-extension-manager"
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
            log_warn "安装 $package 失败"
        fi
    fi
done

# 3. 创建fcitx5自动启动配置
log_info "创建fcitx5自动启动配置..."

AUTOSTART_DIR="$HOME/.config/autostart"
mkdir -p "$AUTOSTART_DIR"

FCITX5_DESKTOP="/usr/share/applications/org.fcitx.Fcitx5.desktop"
if [ -f "$FCITX5_DESKTOP" ]; then
    cp "$FCITX5_DESKTOP" "$AUTOSTART_DIR/"
    log_info "已创建fcitx5自动启动配置"
else
    log_warn "未找到fcitx5桌面文件"
fi

# 4. 设置环境变量
log_info "设置环境变量..."

PROFILE_FILE="$HOME/.profile"
if grep -q "GTK_IM_MODULE=fcitx" "$PROFILE_FILE"; then
    log_info "环境变量已配置，跳过"
else
    backup_file "$PROFILE_FILE"
    cat >> "$PROFILE_FILE" << 'EOF'

# fcitx5 input method settings
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
EOF
    log_info "已添加fcitx5环境变量到 ~/.profile"
fi

# 完成
log_info "=========================================="
log_info "配置完成！"
log_info "=========================================="
echo ""
echo "请在扩展管理器中安装以下扩展："
echo "1. Kimpanel (输入法面板) - 必须"
echo "   完整名称: Input Method Panel"
echo ""
echo "2. AppIndicator (系统托盘) - 推荐"
echo "   完整名称: AppIndicator and KStatusNotifierItem Support"
echo ""
echo "操作步骤：切换到'浏览'标签页 -> 搜索扩展 -> 点击安装 -> 注销或重启"
echo ""
echo "日志: ${LOG_DIR}/fix.log"
echo "复制提示: Ctrl+Shift+C (不要用 Ctrl+C)"
echo "=========================================="
echo ""

read -p "按回车键打开扩展管理器..."

if command_exists extension-manager; then
    log_info "正在打开扩展管理器..."
    extension-manager &
else
    log_warn "未找到 extension-manager 命令"
fi