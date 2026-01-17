#!/bin/bash

# 安装中文支持（语言包和字体）
# 作者: cold-land
# 版本: 1.0

set -e

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# 引入通用工具函数
source "${PROJECT_ROOT}/common/utils.sh"

# 初始化目录
init_dirs

log_info "===== 开始安装中文支持 ====="
log_info "时间: $(date '+%Y-%m-%d %H:%M:%S')"

# 检查是否为 root 用户
if ! is_root; then
    log_error "此脚本需要 root 权限运行"
    exit 1
fi

# 更新软件包列表
log_info "更新软件包列表..."
if sudo apt update; then
    log_info "软件包列表更新成功"
else
    log_error "软件包列表更新失败"
    exit 1
fi

# 安装中文字体
log_info "安装中文字体..."
if sudo apt install -y \
    fonts-noto-cjk \
    fonts-wqy-zenhei \
    fonts-wqy-microhei; then
    log_info "中文字体安装成功"
else
    log_error "中文字体安装失败"
    exit 1
fi

# 刷新字体缓存
log_info "刷新字体缓存..."
if sudo fc-cache -fv; then
    log_info "字体缓存刷新成功"
else
    log_warn "字体缓存刷新失败，但不影响使用"
fi

# 显示完成信息
echo ""
echo "安装完成！"
echo ""
echo "已安装中文字体："
echo "  - Noto CJK（覆盖中日韩）"
echo "  - 文泉驿正黑"
echo "  - 文泉驿微米黑"
echo ""
echo "⚠️  如果系统语言未显示为中文，请运行："
echo "  sudo dpkg-reconfigure locales"
echo "  选择 zh_CN.UTF-8 UTF-8 并设置为默认"
echo ""
echo "日志: ${LOG_DIR}/fix.log"
echo ""
log_info "===== 中文支持安装完成 ====="