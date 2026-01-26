#!/bin/bash
# 安装常用工具

# 引入通用工具函数
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/utils.sh"

# 初始化目录
init_dirs

log_info "=========================================="
log_info "开始安装常用工具"
log_info "=========================================="

# 获取当前用户
CURRENT_USER=$(whoami)
log_info "当前用户: $CURRENT_USER"

# 检查packages.list文件是否存在
PACKAGES_FILE="${CONFIG_DIR}/packages.list"
if [ ! -f "$PACKAGES_FILE" ]; then
    log_error "未找到包列表文件: $PACKAGES_FILE"
    exit 1
fi

# 读取包列表（跳过注释和空行，同时剔除行内注释）
PACKAGES=()
while IFS= read -r line; do
    # 第一步：删除行内注释（# 及之后的所有内容）
    line=${line%%#*}
    # 第二步：跳过空行（剔除注释后为空的行）和纯注释行
    if [[ -z "$line" ]] || [[ "$line" =~ ^[[:space:]]*# ]]; then
        continue
    fi
    # 第三步：去除首尾空格
    line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if [[ -n "$line" ]]; then
        PACKAGES+=("$line")
    fi
done < "$PACKAGES_FILE"

if [ ${#PACKAGES[@]} -eq 0 ]; then
    log_warn "未找到需要安装的包"
    exit 0
fi

log_info "找到 ${#PACKAGES[@]} 个需要检查的包"

# 检查并安装包
INSTALLED=0
SKIPPED=0
FAILED=0

for package in "${PACKAGES[@]}"; do
    if dpkg -l | grep -q "^ii  $package"; then
        log_info "$package 已安装，跳过"
        SKIPPED=$((SKIPPED + 1))
    else
        log_info "安装 $package..."
        sudo apt install -y "$package"
        if [ $? -eq 0 ]; then
            log_info "成功安装 $package"
            INSTALLED=$((INSTALLED + 1))
        else
            log_warn "安装 $package 失败"
            FAILED=$((FAILED + 1))
        fi
    fi
done

# 完成
log_info "=========================================="
log_info "安装完成！"
log_info "=========================================="
echo ""
echo "安装统计："
echo "  - 已安装: $INSTALLED"
echo "  - 已跳过: $SKIPPED"
echo "  - 失败: $FAILED"
echo ""
echo "日志: ${LOG_DIR}/fix.log"
