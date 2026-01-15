# 桌面Linux避坑脚本

一个帮助Linux桌面用户避免常见问题和配置陷阱的自动化脚本集合。

## 项目简介

本项目旨在解决从Windows转向Linux桌面环境时遇到的常见问题，提供开箱即用的初始化配置方案。目前专注于Debian 13系统。

## 系统要求

- 操作系统：Debian 13 (trixie)
- Shell：Bash
- 需要root权限（初始化阶段）

## 快速开始

```bash
# 下载项目
wget https://github.com/cold-land/dont-step-linux-pits/archive/refs/heads/main.zip
unzip main.zip
cd dont-step-linux-pits-main

# 运行主菜单（首次运行会自动检测并引导初始化）
bash main.sh
```

## 菜单操作

- **n/p**: 下一页/上一页
- **g**: 跳转到指定页
- **q**: 退出
- **数字**: 查看脚本详细信息
- **e**: 执行脚本
- **b**: 返回列表

## 项目结构

```
dont-step-linux-pits/
├── main.sh              # 主导航菜单
├── init/                # 初始化脚本
├── fixs/                # 修复脚本
├── common/              # 通用工具函数
├── config/              # 配置文件
├── logs/                # 脚本执行日志
└── backup/              # 文件备份目录
```

## 脚本列表

### 初始化脚本

- **first-setup.sh**: 修复PATH环境变量、sudo组配置和国内软件源

### 修复脚本

- **fix-fcitx5-default.sh**: 配置fcitx5为默认输入法
- **fix-user-dirs-english.sh**: 将用户目录中的中文名称改为英文
- **fix-install-common-tools.sh**: 安装常用工具（curl、wget、vim等）

---

## 贡献指南

欢迎所有形式的贡献！无论你只是遇到了问题，还是愿意贡献代码，我们都非常感谢。

### 报告问题

如果你在使用过程中遇到了问题，或者发现了一个新的"坑"，请按照以下步骤报告：

1. **检查是否已有相关Issue**：
   - 在 [GitHub Issues](https://github.com/cold-land/dont-step-linux-pits/issues) 中搜索
   - 如果已有相关Issue，请在其中补充你的信息

2. **创建新的Issue**：
   - 使用清晰的标题描述问题
   - 在Issue中包含以下信息：
     - 系统版本：`cat /etc/os-release`
     - 操作步骤：详细描述你是如何遇到这个问题的
     - 预期行为：你期望发生什么
     - 实际行为：实际发生了什么
     - 错误信息：如果有错误，请提供完整错误信息
     - 日志文件：如果有，请提供 `~/dont-step-linux-pits/logs/fix.log` 的相关部分

3. **提供解决方案（可选）**：
   - 如果你已经找到了解决方案，请分享出来
   - 这将帮助其他遇到相同问题的人

4. **等待回复**：
   - 我们会尽快查看并回复你的Issue
   - 如果需要更多信息，我们会在Issue中询问

### 贡献代码

如果你愿意编写脚本来修复问题，请按照以下步骤：

#### 1. 创建修复脚本

在 `fixs/` 目录下创建新的脚本文件，命名格式为 `fix-xxx.sh`。

#### 2. 创建描述文件

每个脚本都必须有一个对应的 `.desc` 描述文件（命名格式：`fix-xxx.sh.desc`）：

```
title: 脚本标题
author: 你的名字
version: 1.0
date: 2026-01-14
requires: 依赖包1,依赖包2
risk: low
reboot: false
tags: tag1,tag2

description: |
  脚本的详细描述
  
  解决的问题：
  - 问题1
  - 问题2
  
  注意事项：
  - 注意点1
  - 注意点2
```

**字段说明：**
- **必填字段**: title, description
- **可选字段**: author, version, date, requires, risk, reboot, tags
- 单行字段必须放在多行字段之前

#### 3. 编写脚本

- 使用 `source "${SCRIPT_DIR}/../common/utils.sh"` 引入通用工具函数
- 脚本应该简洁，只包含核心执行逻辑
- 使用 `log_info`、`log_warn`、`log_error` 记录日志
- 使用 `backup_file` 备份修改的文件
- 如果需要root权限，在脚本开头检查并提示

#### 4. 测试脚本

- 在虚拟机中测试脚本
- 确保脚本在Debian 13上正常运行
- 检查日志文件是否正确记录
- 如果需要重启，测试重启后的效果

#### 5. 提交Pull Request

- Fork 本仓库
- 创建新的分支：`git checkout -b fix-your-problem`
- 提交你的更改：`git commit -m "Add: 修复XXX问题"`
- 推送到你的分支：`git push origin fix-your-problem`
- 创建Pull Request

在Pull Request中请说明：
- 这个脚本解决了什么问题
- 如何使用这个脚本
- 测试结果
- 是否有已知的限制或问题

#### 6. 代码审查

我们会尽快审查你的Pull Request，可能会提出一些修改建议。请及时回复并处理这些意见。

---

## 许可证

MIT License

## 联系方式

- GitHub: https://github.com/cold-land/dont-step-linux-pits
- Email: ccshaowei@gmail.com