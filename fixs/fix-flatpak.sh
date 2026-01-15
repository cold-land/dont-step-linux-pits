#!/bin/bash

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/utils.sh"

# 检查是否以 root 权限运行
if [ "$EUID" -eq 0 ]; then
    log_error "此脚本需要以普通用户身份运行"
    exit 1
fi

log_info "=========================================="
log_info "开始安装 Flatpak"
log_info "=========================================="

# 1. 安装 flatpak
log_info "安装 flatpak..."
if dpkg -l | grep -q "^ii  flatpak "; then
    log_info "flatpak 已安装，跳过"
else
    sudo apt install -y flatpak
    if [ $? -eq 0 ]; then
        log_info "flatpak 安装成功"
    else
        log_error "flatpak 安装失败"
        exit 1
    fi
fi

# 2. 安装 GNOME Flatpak 插件
log_info "安装 GNOME Flatpak 插件..."
if dpkg -l | grep -q "^ii  gnome-software-plugin-flatpak "; then
    log_info "gnome-software-plugin-flatpak 已安装，跳过"
else
    sudo apt install -y gnome-software-plugin-flatpak
    if [ $? -eq 0 ]; then
        log_info "gnome-software-plugin-flatpak 安装成功"
    else
        log_error "gnome-software-plugin-flatpak 安装失败"
        exit 1
    fi
fi

# 3. 添加 Flathub 仓库
log_info "添加 Flathub 仓库..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
if [ $? -eq 0 ]; then
    log_info "Flathub 仓库添加成功"
else
    log_warn "Flathub 仓库添加失败（可能已经添加）"
fi

# 4. 配置国内镜像源（上海交通大学）
log_info "配置 Flathub 国内镜像源（上海交通大学）..."
# 检查 wget 是否安装
if ! command -v wget &> /dev/null; then
    log_info "wget 未安装，正在安装..."
    sudo apt install -y wget
fi

# 修改为上海交通大学镜像
flatpak remote-modify flathub --url=https://mirror.sjtu.edu.cn/flathub
if [ $? -eq 0 ]; then
    log_info "Flathub 镜像源配置成功"
else
    log_warn "Flathub 镜像源配置失败，尝试导入 GPG 密钥..."
    # 下载 GPG 密钥
    wget https://mirror.sjtu.edu.cn/flathub/flathub.gpg -O /tmp/flathub.gpg
    if [ $? -eq 0 ]; then
        flatpak remote-modify --gpg-import=/tmp/flathub.gpg flathub
        rm -f /tmp/flathub.gpg
        if [ $? -eq 0 ]; then
            log_info "Flathub 镜像源配置成功（已导入 GPG 密钥）"
        else
            log_warn "Flathub 镜像源配置失败，将使用官方源"
            flatpak remote-modify flathub --url=https://dl.flathub.org/repo/
        fi
    else
        log_warn "GPG 密钥下载失败，将使用官方源"
        flatpak remote-modify flathub --url=https://dl.flathub.org/repo/
    fi
fi

# 更新 Flatpak 应用列表
log_info "更新 Flatpak 应用列表..."
flatpak update --appstream

log_info "=========================================="
log_info "Flatpak 安装完成！"
log_info "=========================================="
echo ""
echo "后续操作："
echo "1. 重启系统以完成设置"
echo "2. 重启后可以在 GNOME Software 中浏览和安装 Flatpak 应用"
echo "3. 或者使用命令行安装应用："
echo "   flatpak search <应用名称>"
echo "   flatpak install flathub <应用ID>"
echo ""
echo "注意事项："
echo "- Flathub 是 Flatpak 应用的主要来源"
echo "- 可以访问 https://flathub.org/ 浏览可用的应用"
echo ""
echo "日志: ${LOG_DIR}/fix.log"