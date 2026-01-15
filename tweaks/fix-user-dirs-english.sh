#!/bin/bash
# 将用户目录中的中文名称改为英文

# 引入通用工具函数
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/utils.sh"

# 初始化目录
init_dirs

log_info "=========================================="
log_info "开始修复用户目录中文名称"
log_info "=========================================="

# 获取当前用户
CURRENT_USER=$(whoami)
log_info "当前用户: $CURRENT_USER"

# 检查xdg-user-dirs是否安装
if ! command_exists xdg-user-dirs-update; then
    log_error "未找到 xdg-user-dirs-update 命令"
    log_error "请先安装 xdg-user-dirs 包"
    exit 1
fi

# 检查当前项目目录是否在即将被改名的目录下
CURRENT_DIR="$(pwd)"
CURRENT_DIR_NAME=$(basename "$CURRENT_DIR")
PARENT_DIR=$(dirname "$CURRENT_DIR")
PARENT_DIR_NAME=$(basename "$PARENT_DIR")

# 检查父目录是否是中文目录名
if [[ "$PARENT_DIR_NAME" =~ ^(桌面|下载|文档|模板|公共|音乐|图片|视频)$ ]]; then
    echo ""
    echo "=========================================="
    echo "⚠️  警告"
    echo "=========================================="
    echo "检测到项目在即将被改名的目录下运行"
    echo "当前目录: $CURRENT_DIR"
    echo "父目录: $PARENT_DIR"
    echo ""
    echo "执行此脚本后，'$PARENT_DIR_NAME' 将被改为英文目录名"
    echo "这可能导致日志文件无法正常写入"
    echo ""
    echo "建议："
    echo "1. 将项目移动到其他目录（如 ~/Documents 或 ~/dont-step-linux-pits）"
    echo "2. 然后在新位置运行此脚本"
    echo ""
    read -p "是否继续执行？[y/N]: " continue_choice
    if [[ ! "$continue_choice" =~ ^[Yy]$ ]]; then
        log_info "用户取消执行"
        exit 0
    fi
    log_warn "用户选择在中文目录下继续执行，可能会有日志错误"
fi

# 检查用户目录是否包含中文
log_info "检查用户目录名称..."

HOME_DIR="$HOME"
HAS_CHINESE=0

if [ -d "$HOME_DIR/桌面" ] || [ -d "$HOME_DIR/下载" ] || [ -d "$HOME_DIR/文档" ] || \
   [ -d "$HOME_DIR/音乐" ] || [ -d "$HOME_DIR/图片" ] || [ -d "$HOME_DIR/视频" ]; then
    HAS_CHINESE=1
fi

if [ $HAS_CHINESE -eq 0 ]; then
    log_info "用户目录已经是英文名称，无需修复"
    exit 0
fi

log_info "检测到用户目录包含中文名称"

# 备份配置文件
CONFIG_DIR="$HOME/.config"
USER_DIRS_FILE="$CONFIG_DIR/user-dirs.dirs"
USER_DIRS_LOCALE="$CONFIG_DIR/user-dirs.locale"

log_info "备份配置文件..."
if [ -f "$USER_DIRS_FILE" ]; then
    backup_file "$USER_DIRS_FILE"
fi

if [ -f "$USER_DIRS_LOCALE" ]; then
    backup_file "$USER_DIRS_LOCALE"
fi

# 定义目录映射
declare -A DIR_MAP=(
    ["桌面"]="Desktop"
    ["下载"]="Downloads"
    ["文档"]="Documents"
    ["模板"]="Templates"
    ["公共"]="Public"
    ["音乐"]="Music"
    ["图片"]="Pictures"
    ["视频"]="Videos"
)

# 处理每个中文目录
for chinese_dir in "${!DIR_MAP[@]}"; do
    english_dir="${DIR_MAP[$chinese_dir]}"
    chinese_path="$HOME_DIR/$chinese_dir"
    english_path="$HOME_DIR/$english_dir"

    if [ -d "$chinese_path" ]; then
        log_info "处理目录: $chinese_dir -> $english_dir"

        if [ -d "$english_path" ]; then
            log_info "英文目录 $english_dir 已存在"

            if [ -n "$(ls -A "$english_path" 2>/dev/null)" ]; then
                log_warn "英文目录 $english_dir 不为空"
                echo ""
                echo "警告：$english_path 目录已存在且包含文件"
                echo "请选择处理方式："
                echo "1. 保留现有文件，跳过移动"
                echo "2. 将中文目录的文件移动到现有目录"
                read -p "请选择 [1/2]: " choice

                if [ "$choice" = "2" ]; then
                    log_info "将 $chinese_path 的内容移动到 $english_path"
                    mv "$chinese_path"/* "$english_path"/ 2>/dev/null
                    if [ $? -eq 0 ]; then
                        log_info "移动成功"
                        rmdir "$chinese_path" 2>/dev/null
                    else
                        log_warn "移动失败，部分文件可能未移动"
                    fi
                else
                    log_info "跳过移动 $chinese_dir"
                fi
            else
                log_info "英文目录为空，直接删除"
                rmdir "$english_path" 2>/dev/null
                mv "$chinese_path" "$english_path"
                log_info "移动成功"
            fi
        else
            log_info "创建英文目录并移动文件"
            mv "$chinese_path" "$english_path"
            log_info "移动成功"
        fi
    fi
done

# 更新配置文件
log_info "更新配置文件..."

cat > "$USER_DIRS_FILE" << 'EOF'
# This file is written by xdg-user-dirs-update
# If you want to change or add directories, just edit the line you're
# interested in. All local changes will be retained on the next run.
# Format is XDG_xxx_DIR="$HOME/yyy", where yyy is a shell-escaped
# homedir-relative path, or XDG_xxx_DIR="/yyy", where /yyy is an
# absolute path. No other format is supported.
# 
XDG_DESKTOP_DIR="$HOME/Desktop"
XDG_DOWNLOAD_DIR="$HOME/Downloads"
XDG_TEMPLATES_DIR="$HOME/Templates"
XDG_PUBLICSHARE_DIR="$HOME/Public"
XDG_DOCUMENTS_DIR="$HOME/Documents"
XDG_MUSIC_DIR="$HOME/Music"
XDG_PICTURES_DIR="$HOME/Pictures"
XDG_VIDEOS_DIR="$HOME/Videos"
EOF

log_info "已更新配置文件"

cat > "$USER_DIRS_LOCALE" << 'EOF'
en_US
EOF

log_info "已设置语言环境为英文"

# 更新文件浏览器书签
log_info "更新文件浏览器书签..."

BOOKMARKS_FILES=(
    "$HOME/.config/gtk-3.0/bookmarks"
    "$HOME/.config/gtk-4.0/bookmarks"
    "$HOME/.config/gtk-2.0/bookmarks"
    "$HOME/.config/nautilus/bookmarks"
)

BOOKMARKS_UPDATED=0

for bookmarks_file in "${BOOKMARKS_FILES[@]}"; do
    if [ -f "$bookmarks_file" ]; then
        log_info "处理书签文件: $bookmarks_file"
        backup_file "$bookmarks_file"
        
        sed -i "s|file://$HOME_DIR/%E6%A1%8C%E9%9D%A2|file://$HOME_DIR/Desktop|g" "$bookmarks_file"
        sed -i "s|file://$HOME_DIR/%E4%B8%8B%E8%BD%BD|file://$HOME_DIR/Downloads|g" "$bookmarks_file"
        sed -i "s|file://$HOME_DIR/%E6%96%87%E6%A1%A3|file://$HOME_DIR/Documents|g" "$bookmarks_file"
        sed -i "s|file://$HOME_DIR/%E6%A8%A1%E6%9D%BF|file://$HOME_DIR/Templates|g" "$bookmarks_file"
        sed -i "s|file://$HOME_DIR/%E5%85%AC%E5%85%B1|file://$HOME_DIR/Public|g" "$bookmarks_file"
        sed -i "s|file://$HOME_DIR/%E9%9F%B3%E4%B9%90|file://$HOME_DIR/Music|g" "$bookmarks_file"
        sed -i "s|file://$HOME_DIR/%E5%9B%BE%E7%89%87|file://$HOME_DIR/Pictures|g" "$bookmarks_file"
        sed -i "s|file://$HOME_DIR/%E8%A7%86%E9%A2%91|file://$HOME_DIR/Videos|g" "$bookmarks_file"
        
        BOOKMARKS_UPDATED=$((BOOKMARKS_UPDATED + 1))
        log_info "已更新书签文件: $bookmarks_file"
    fi
done

if [ $BOOKMARKS_UPDATED -gt 0 ]; then
    log_info "已更新 $BOOKMARKS_UPDATED 个书签文件"
else
    log_info "未找到需要更新的书签"
fi

# 完成
log_info "=========================================="
log_info "配置完成！"
log_info "=========================================="
echo ""
echo "已将用户目录改为英文名称。"
echo ""
echo "⚠️  重启后如果弹出对话框，请选择'保留旧的名称'并勾选'不再询问'"
echo ""
echo "日志: ${LOG_DIR}/fix.log"
echo ""

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
