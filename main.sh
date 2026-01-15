#!/bin/bash
# 桌面Linux避坑脚本 - 主导航菜单
# 使用方法：bash main.sh

# 引入通用工具函数
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common/utils.sh"

# 初始化目录
init_dirs

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 分页设置
PAGE_SIZE=10

# 获取所有可用的脚本（包含 desc 文件）
get_available_scripts() {
    local scripts=()
    for script in "${SCRIPT_DIR}/fixs"/*.sh; do
        if [ -f "$script" ]; then
            local desc_file="${script}.desc"
            if [ -f "$desc_file" ]; then
                # 验证 desc 文件
                if validate_desc_file "$desc_file"; then
                    scripts+=("$script")
                fi
            fi
        fi
    done
    echo "${scripts[@]}"
}

# 验证 desc 文件
validate_desc_file() {
    local desc_file="$1"
    local script_name=$(basename "$desc_file" | sed 's/.desc$//')
    
    # 检查必填字段
    if ! grep -q "^title:" "$desc_file" 2>/dev/null; then
        log_warn "跳过脚本 ${script_name}: 缺少 title 字段"
        return 1
    fi
    
    if ! grep -q "^description:" "$desc_file" 2>/dev/null; then
        log_warn "跳过脚本 ${script_name}: 缺少 description 字段"
        return 1
    fi
    
    return 0
}

# 读取 desc 文件的字段
read_desc_field() {
    local desc_file="$1"
    local field="$2"
    grep "^${field}:" "$desc_file" 2>/dev/null | cut -d':' -f2- | sed 's/^[[:space:]]*//'
}

# 读取 desc 文件的字段（带默认值）
read_desc_field_safe() {
    local desc_file="$1"
    local field="$2"
    local default="$3"
    
    local value=$(grep "^${field}:" "$desc_file" 2>/dev/null | cut -d':' -f2- | sed 's/^[[:space:]]*//')
    
    if [ -z "$value" ]; then
        echo "$default"
    else
        echo "$value"
    fi
}

# 读取 desc 文件的多行字段
read_desc_multiline() {
    local desc_file="$1"
    local field="$2"
    awk "/^${field}:/,0" "$desc_file" | tail -n +2 | sed 's/^  //'
}

# 显示系统信息
show_system_info() {
    echo ""
    echo "=========================================="
    echo "系统信息"
    echo "=========================================="
    echo "操作系统: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo "内核版本: $(uname -r)"
    echo "当前用户: $(whoami)"
    echo "Debian版本: $(get_debian_version)"
    echo "=========================================="
    echo ""
}

# 显示指定页的脚本列表
show_scripts_page() {
    local page=$1
    local scripts=($(get_available_scripts))
    local total=${#scripts[@]}

    if [ $total -eq 0 ]; then
        echo "暂无可用的修复脚本"
        return
    fi

    local total_pages=$(( (total + PAGE_SIZE - 1) / PAGE_SIZE ))
    if [ $page -lt 1 ]; then
        page=1
    elif [ $page -gt $total_pages ]; then
        page=$total_pages
    fi

    local start=$(( (page - 1) * PAGE_SIZE ))
    local end=$(( start + PAGE_SIZE ))
    if [ $end -gt $total ]; then
        end=$total
    fi

    echo "可用的修复脚本 (第 ${page}/${total_pages} 页):"
    echo "=========================================="

    local idx=0
    for i in $(seq $start $((end - 1))); do
        local script="${scripts[$i]}"
        local desc_file="${script}.desc"
        local script_name=$(basename "$script")
        local idx=$((i + 1))

        local title=$(read_desc_field "$desc_file" "title")
        local risk=$(read_desc_field_safe "$desc_file" "risk" "unknown")
        local reboot=$(read_desc_field_safe "$desc_file" "reboot" "false")

        local line="${idx}. ${title}"
        if [ -n "$risk" ] && [ "$risk" != "unknown" ]; then
            case "$risk" in
                low) line="${line} [低风险]" ;;
                medium) line="${line} [中风险]" ;;
                high) line="${line} [高风险]" ;;
                *) line="${line} [${risk}风险]" ;;
            esac
        fi
        if [ "$reboot" = "true" ]; then
            line="${line} ⚠️需重启"
        fi
        echo "$line"
    done

    echo "=========================================="
    echo ""
    if [ $total_pages -gt 1 ]; then
        echo "操作: n=下一页 | p=上一页 | g=跳转页 | q=退出"
    else
        echo "操作: q=退出"
    fi
    echo "输入脚本编号查看详情或执行: "
}

# 显示脚本详细信息
show_script_detail() {
    local script="$1"
    local desc_file="${script}.desc"
    local script_name=$(basename "$script")

    local title=$(read_desc_field "$desc_file" "title")
    local description=$(read_desc_multiline "$desc_file" "description")
    local requires=$(read_desc_field_safe "$desc_file" "requires" "")
    local risk=$(read_desc_field_safe "$desc_file" "risk" "unknown")
    local reboot=$(read_desc_field_safe "$desc_file" "reboot" "false")

    clear
    echo "=========================================="
    echo "脚本详细信息"
    echo "=========================================="
    echo "脚本: ${script_name}"
    echo "标题: ${title}"
    echo ""
    if [ -n "$requires" ]; then
        echo "依赖: ${requires}"
    fi
    if [ -n "$risk" ] && [ "$risk" != "unknown" ]; then
        echo "风险等级: ${risk}"
    fi
    if [ "$reboot" = "true" ]; then
        echo "⚠️  需要重启"
    fi
    echo ""
    echo "详细描述:"
    echo "$description"
    echo "=========================================="
    echo ""
    echo "操作: e=执行 | b=返回"
}

# 执行修复脚本
run_fix_script() {
    local script="$1"
    local script_name=$(basename "$script")

    echo ""
    echo "=========================================="
    echo "正在执行: ${script_name}"
    echo "=========================================="
    echo ""

    # 检查脚本是否需要root权限
    if grep -q "is_root" "$script"; then
        if ! is_root; then
            echo "此脚本需要root权限，正在使用sudo执行..."
            sudo bash "$script"
        else
            bash "$script"
        fi
    else
        bash "$script"
    fi

    echo ""
    echo "=========================================="
    echo "执行完成"
    echo "=========================================="
    read -p "按回车键继续..."
}

# 检测是否需要初始化
check_need_init() {
    # 检查1: /etc/profile中是否包含/usr/sbin配置
    if [ -f /etc/profile ]; then
        if ! grep -q "export PATH.*:/usr/sbin" /etc/profile 2>/dev/null; then
            return 0
        fi
    else
        return 0
    fi

    # 检查2: 当前用户是否在sudo组
    local current_user=$(whoami)
    if ! user_in_sudo "$current_user"; then
        return 0
    fi

    # 检查3: 是否已经配置了清华大学源
    if [ -f /etc/apt/sources.list ]; then
        if ! grep -q "mirrors.tuna.tsinghua.edu.cn" /etc/apt/sources.list; then
            return 0
        fi
    fi

    # 所有检查都通过，不需要初始化
    return 1
}

# 执行初始化
do_init() {
    clear
    show_system_info

    local init_script="${SCRIPT_DIR}/init/first-setup.sh"
    local init_desc="${init_script}.desc"

    echo "=========================================="
    echo "首次运行检测"
    echo "=========================================="
    echo ""
    echo "检测到系统需要初始化"
    echo ""

    if [ -f "$init_desc" ]; then
        local title=$(read_desc_field "$init_desc" "title")
        local description=$(read_desc_multiline "$init_desc" "description")
        local requires=$(read_desc_field_safe "$init_desc" "requires" "")
        local risk=$(read_desc_field_safe "$init_desc" "risk" "unknown")
        local reboot=$(read_desc_field_safe "$init_desc" "reboot" "false")

        echo "标题: ${title}"
        if [ -n "$requires" ]; then
            echo "依赖: ${requires}"
        fi
        if [ -n "$risk" ] && [ "$risk" != "unknown" ]; then
            echo "风险等级: ${risk}"
        fi
        if [ "$reboot" = "true" ]; then
            echo "⚠️  需要重启"
        fi
        echo ""
        echo "详细描述:"
        echo "$description"
    fi

    echo "=========================================="
    echo ""

    # 检查当前是否为root用户
    if ! is_root; then
        read -p "是否现在切换到root用户并执行初始化？[Y/n]: " confirm
        if [ "$confirm" = "n" ] || [ "$confirm" = "N" ]; then
            echo "已取消初始化"
            echo ""
            echo "提示：您可以稍后手动执行以下命令："
            echo "  su"
            echo "  bash ${SCRIPT_DIR}/init/first-setup.sh"
            echo ""
            read -p "按回车键继续..."
            return 1
        fi

        echo ""
        echo "请输入root密码切换到root用户..."
        echo ""
        su - root -c "bash ${SCRIPT_DIR}/init/first-setup.sh"

        if [ $? -eq 0 ]; then
            echo ""
            echo "=========================================="
            echo "初始化完成！"
            echo "=========================================="
            echo ""
            echo "请按以下步骤操作："
            echo "1. 退出root用户（如果还在root）: exit"
            echo "2. 验证sudo是否可用: sudo whoami"
            echo "3. 如果sudo不可用，请重启系统: sudo reboot"
            echo "4. 重启后重新运行: bash main.sh"
            echo ""
            read -p "按回车键退出..."
            exit 0
        else
            echo ""
            echo "初始化失败，请查看日志: ${LOG_DIR}/fix.log"
            echo ""
            read -p "按回车键继续..."
            return 1
        fi
    else
        # 已经是root用户，直接执行初始化
        bash "${SCRIPT_DIR}/init/first-setup.sh"
        if [ $? -eq 0 ]; then
            echo ""
            echo "=========================================="
            echo "初始化完成！"
            echo "=========================================="
            echo ""
            echo "请按以下步骤操作："
            echo "1. 退出root用户: exit"
            echo "2. 验证sudo是否可用: sudo whoami"
            echo "3. 如果sudo不可用，请重启系统: sudo reboot"
            echo "4. 重启后重新运行: bash main.sh"
            echo ""
            read -p "按回车键退出..."
            exit 0
        else
            echo ""
            echo "初始化失败，请查看日志: ${LOG_DIR}/fix.log"
            echo ""
            read -p "按回车键继续..."
            return 1
        fi
    fi
}

# 主菜单循环
main() {
    # 检测是否需要初始化
    if check_need_init; then
        do_init
        if [ $? -ne 0 ]; then
            # 初始化失败或取消，询问是否继续
            echo ""
            read -p "初始化未完成，是否继续进入主菜单？[y/N]: " continue_choice
            if [ "$continue_choice" != "y" ] && [ "$continue_choice" != "Y" ]; then
                exit 0
            fi
        fi
    fi

    local current_page=1
    local scripts=($(get_available_scripts))
    local total=${#scripts[@]}

    # 主菜单循环
    while true; do
        clear
        show_system_info
        show_scripts_page $current_page

        read -p "" choice

        case "$choice" in
            q|Q)
                echo "退出"
                exit 0
                ;;
            n|N)
                local total_pages=$(( (total + PAGE_SIZE - 1) / PAGE_SIZE ))
                if [ $current_page -lt $total_pages ]; then
                    current_page=$((current_page + 1))
                fi
                ;;
            p|P)
                if [ $current_page -gt 1 ]; then
                    current_page=$((current_page - 1))
                fi
                ;;
            g|G)
                local total_pages=$(( (total + PAGE_SIZE - 1) / PAGE_SIZE ))
                if [ $total_pages -gt 1 ]; then
                    read -p "跳转到第几页 (1-${total_pages}): " goto_page
                    if [[ "$goto_page" =~ ^[0-9]+$ ]] && [ $goto_page -ge 1 ] && [ $goto_page -le $total_pages ]; then
                        current_page=$goto_page
                    fi
                fi
                ;;
            *)
                # 检查是否是脚本编号
                if [[ "$choice" =~ ^[0-9]+$ ]]; then
                    local idx=$((choice - 1))
                    if [ $idx -ge 0 ] && [ $idx -lt $total ]; then
                        local script="${scripts[$idx]}"
                        show_script_detail "$script"
                        read -p "" detail_choice
                        case "$detail_choice" in
                            e|E)
                                run_fix_script "$script"
                                ;;
                            b|B)
                                # 返回列表
                                ;;
                        esac
                    fi
                fi
                ;;
        esac
    done
}

# 启动主程序
main