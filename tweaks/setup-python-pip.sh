#!/bin/bash
# 配置Python环境和pip

# 引入通用工具函数
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/utils.sh"

# 初始化目录
init_dirs

log_info "=========================================="
log_info "开始配置Python环境和pip"
log_info "=========================================="

# 获取当前用户
CURRENT_USER=$(whoami)
log_info "当前用户: $CURRENT_USER"

# 检查python3是否存在
if ! command_exists python3; then
    log_error "未找到 python3 命令"
    log_error "请先安装 python3 包"
    exit 1
fi

PYTHON3_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
log_info "检测到 Python 版本: $PYTHON3_VERSION"

# 1. 检查并安装 python-is-python3
log_info "检查 python 命令..."
if command_exists python; then
    log_info "python 命令已存在，跳过安装 python-is-python3"
else
    log_info "python 命令不存在，正在安装 python-is-python3..."
    sudo apt install -y python-is-python3
    if [ $? -eq 0 ]; then
        log_info "成功安装 python-is-python3"
    else
        log_warn "安装 python-is-python3 失败"
    fi
fi

# 2. 检查并安装 python3-pip
log_info "检查 pip 命令..."
if command_exists pip || command_exists pip3; then
    log_info "pip 命令已存在，跳过安装 python3-pip"
else
    log_info "pip 命令不存在，正在安装 python3-pip..."
    sudo apt install -y python3-pip
    if [ $? -eq 0 ]; then
        log_info "成功安装 python3-pip"
    else
        log_error "安装 python3-pip 失败"
        exit 1
    fi
fi

# 3. 配置 pip 国内源
log_info "配置 pip 国内源（清华大学镜像源）..."
pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
if [ $? -eq 0 ]; then
    log_info "成功配置 pip 国内源"
else
    log_warn "配置 pip 国内源失败"
fi

# 4. 更新 pip 本身
log_info "更新 pip 本身..."
pip install --upgrade pip
if [ $? -eq 0 ]; then
    log_info "成功更新 pip"
else
    log_warn "更新 pip 失败"
fi

# 5. 显示版本信息
echo ""
echo "=========================================="
echo "配置完成！"
echo "=========================================="
echo ""
echo "Python 版本:"
python --version 2>/dev/null || python3 --version
echo ""
echo "pip 版本:"
pip --version 2>/dev/null || pip3 --version
echo ""
echo "pip 配置:"
echo "  镜像源: $(pip config get global.index-url 2>/dev/null || echo '未配置')"
echo ""
echo "日志: ${LOG_DIR}/fix.log"