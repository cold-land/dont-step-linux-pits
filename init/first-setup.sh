#!/bin/bash
# 修复PATH环境变量、sudo组配置和国内软件源

# 引入通用工具函数
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/utils.sh"

# 获取普通用户名（假设是UID大于1000的第一个用户）
NORMAL_USER=$(awk -F: '$3 >= 1000 && $3 < 60000 {print $1; exit}' /etc/passwd)
if [[ -z "$NORMAL_USER" ]]; then
    echo "错误：无法找到普通用户"
    exit 1
fi

# 获取普通用户的home目录
NORMAL_USER_HOME=$(eval echo ~"$NORMAL_USER")

# 初始化目录
init_dirs

log_info "=========================================="
log_info "开始执行初始化修复"
log_info "=========================================="

# 检查是否为root用户
if ! is_root; then
    log_error "此脚本需要root权限运行"
    log_error "请先执行: su"
    exit 1
fi

log_info "检测到当前为root用户"

log_info "检测到普通用户: $NORMAL_USER"

# 询问用户确认用户名
echo ""
read -p "检测到用户名: $NORMAL_USER 是否正确? [Y/n]: " confirm
if [[ "$confirm" =~ ^[Nn]$ ]]; then
    read -p "请输入需要添加到sudo组的用户名: " NORMAL_USER
    # 检查用户是否存在
    if ! id "$NORMAL_USER" &> /dev/null; then
        log_error "用户 $NORMAL_USER 不存在"
        exit 1
    fi
fi

log_info "确认用户: $NORMAL_USER"

# 1. 修复PATH环境变量问题
log_info "检查PATH环境变量..."

# 检查/etc/profile中是否已经包含/usr/sbin配置
if grep -q "export PATH.*:/usr/sbin" /etc/profile 2>/dev/null; then
    log_info "检测到/etc/profile中已包含/usr/sbin配置，跳过"
else
    # 备份原文件
    backup_file /etc/profile

    # 添加PATH配置到/etc/profile（只添加/usr/sbin）
    echo 'export PATH=$PATH:/usr/sbin' >> /etc/profile
    log_info "已将/usr/sbin添加到/etc/profile"

    # 立即生效
    source /etc/profile
    log_info "PATH已立即生效（当前会话）"
fi

# 2. 将用户添加到sudo组
log_info "检查用户sudo组配置..."

if user_in_sudo "$NORMAL_USER"; then
    log_info "用户 $NORMAL_USER 已在sudo组中，跳过"
else
    log_info "将用户 $NORMAL_USER 添加到sudo组..."
    usermod -aG sudo "$NORMAL_USER"
    if [[ $? -eq 0 ]]; then
        log_info "成功将用户 $NORMAL_USER 添加到sudo组"

        # 刷新权限并验证是否成功
        log_info "正在刷新权限并验证..."
        su - "$NORMAL_USER" -c "newgrp sudo -c 'sudo whoami'" &> /dev/null
        if [[ $? -eq 0 ]]; then
            log_info "成功！已成功将 $NORMAL_USER 添加到sudo组并验证通过"
        else
            log_warn "=========================================="
            log_warn "警告：无法立即验证sudo权限"
            log_warn "=========================================="
            log_warn "这可能是由于系统缓存或环境问题导致的"
            log_warn "请执行以下操作："
            log_warn "1. 退出root用户: exit"
            log_warn "2. 重启系统: sudo reboot"
            log_warn "3. 重启后重新登录，然后验证: sudo whoami"
            log_warn "4. 如果sudo仍然不可用，请重新运行此脚本"
            log_warn ""
            log_warn "注意：如果提示'newgrp: command not found'，"
            log_warn "这说明PATH环境变量问题未完全解决，重启后通常会自动修复"
            log_warn "=========================================="
        fi
    else
        log_error "=========================================="
        log_error "错误：添加用户到sudo组失败"
        log_error "=========================================="
        log_error "可能的原因："
        log_error "1. 系统需要重启才能使某些更改生效"
        log_error "2. 系统缓存或环境问题"
        log_error ""
        log_error "建议的解决方案："
        log_error "1. 重启系统: reboot"
        log_error "2. 重启后重新运行此脚本"
        log_error "3. 如果仍然失败，请检查系统日志: journalctl -xe"
        log_error "=========================================="
        exit 1
    fi
fi

# 3. 配置国内软件源
log_info "配置国内软件源..."

# 备份原软件源文件
backup_file /etc/apt/sources.list

# 复制配置文件
if [[ -f "${CONFIG_DIR}/sources.list" ]]; then
    cp "${CONFIG_DIR}/sources.list" /etc/apt/sources.list
    log_info "已配置国内软件源（清华大学镜像）"
else
    log_warn "未找到软件源配置文件: ${CONFIG_DIR}/sources.list"
    log_warn "跳过软件源配置"
fi

# 4. 更新软件包列表
log_info "更新软件包列表..."
apt update
if [[ $? -eq 0 ]]; then
    log_info "软件包列表更新成功"
else
    log_error "软件包列表更新失败"
    log_error "请检查网络连接或软件源配置"
    exit 1
fi

# 完成
log_info "=========================================="
log_info "初始化修复完成！"
log_info "=========================================="
log_info ""

# 修改日志文件所有者为普通用户
if [ -f "${LOG_DIR}/fix.log" ]; then
    chown "${NORMAL_USER}:${NORMAL_USER}" "${LOG_DIR}/fix.log"
    log_info "已将日志文件所有者修改为: $NORMAL_USER"
fi

# 修改日志目录所有者为普通用户
if [ -d "${LOG_DIR}" ]; then
    chown "${NORMAL_USER}:${NORMAL_USER}" "${LOG_DIR}"
    log_info "已将日志目录所有者修改为: $NORMAL_USER"
fi

# 修改备份目录所有者为普通用户
if [ -d "${BACKUP_DIR}" ]; then
    chown "${NORMAL_USER}:${NORMAL_USER}" "${BACKUP_DIR}"
    log_info "已将备份目录所有者修改为: $NORMAL_USER"
fi

echo "=========================================="
echo "初始化修复完成！"
echo "=========================================="
echo ""
echo "重要提示："
echo "1. 配置已写入系统文件，但需要重启或重新登录才能完全生效"
echo "2. 强烈建议立即重启系统，以确保所有配置正确生效"
echo "3. 重启前请保存好所有打开的文件，避免数据丢失"
echo ""
echo "重启后，请执行以下验证："
echo "  - 验证sudo: sudo whoami"
echo "  - 验证PATH: echo \$PATH | grep /usr/sbin"
echo "  - 运行主菜单: bash main.sh"
echo ""
read -p "是否现在重启系统？[Y/n]: " reboot_choice

if [[ "$reboot_choice" =~ ^[Nn]$ ]]; then
    echo ""
    echo "=========================================="
    echo "您选择不立即重启"
    echo "=========================================="
    echo ""
    echo "请执行以下操作："
    echo "1. 退出root用户: exit"
    echo "2. 以普通用户身份执行: source /etc/profile"
    echo "3. 验证sudo: sudo whoami"
    echo "4. 验证PATH: echo \$PATH | grep /usr/sbin"
    echo "5. 运行主菜单: bash main.sh"
    echo ""
    echo "注意：如果遇到问题，建议重启系统后再试"
    echo ""
    log_info "用户选择不立即重启，提示手动source /etc/profile"
else
    echo ""
    echo "系统将在5秒后重启..."
    echo "请保存好所有文件！"
    echo ""
    log_info "用户选择立即重启系统"
    sleep 5
    reboot
fi