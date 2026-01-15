#!/bin/bash
# 通用工具函数库
# 提供日志记录、文件备份、系统检测等共用功能

# 获取脚本根目录
SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 日志目录（使用用户主目录，避免权限问题）
LOG_DIR="$HOME/dont-step-linux-pits/logs"

# 备份目录（使用用户主目录，避免权限问题）
BACKUP_DIR="$HOME/dont-step-linux-pits/backup"

# 配置目录
CONFIG_DIR="${SCRIPT_ROOT}/config"

# 日志记录函数
log_info() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [INFO] $*" | tee -a "${LOG_DIR}/fix.log"
}

log_warn() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [WARN] $*" | tee -a "${LOG_DIR}/fix.log"
}

log_error() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [ERROR] $*" | tee -a "${LOG_DIR}/fix.log"
}

# 文件备份函数
backup_file() {
    local file_path="$1"
    local backup_name

    if [ ! -f "$file_path" ]; then
        log_warn "文件不存在，跳过备份: $file_path"
        return 1
    fi

    # 生成备份文件名（带时间戳）
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local filename=$(basename "$file_path")
    backup_name="${timestamp}_${filename}"

    # 执行备份
    cp "$file_path" "${BACKUP_DIR}/${backup_name}"
    if [ $? -eq 0 ]; then
        log_info "文件已备份: $file_path -> ${BACKUP_DIR}/${backup_name}"
        return 0
    else
        log_error "备份失败: $file_path"
        return 1
    fi
}

# 检测是否为root用户
is_root() {
    [ $EUID -eq 0 ]
}

# 检测命令是否存在
command_exists() {
    command -v "$1" > /dev/null 2>&1
}

# 检测Debian版本
get_debian_version() {
    if [ -f /etc/debian_version ]; then
        cat /etc/debian_version
    else
        echo "unknown"
    fi
}

# 检测当前用户是否在sudo组
user_in_sudo() {
    local username="$1"
    groups "$username" 2>/dev/null | grep -q '\bsudo\b'
}

# 初始化目录
init_dirs() {
    # 创建日志目录
    mkdir -p "$LOG_DIR" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "日志目录: $LOG_DIR"
    else
        echo "警告：无法创建日志目录 $LOG_DIR"
    fi
    
    # 创建备份目录
    mkdir -p "$BACKUP_DIR" 2>/dev/null
}