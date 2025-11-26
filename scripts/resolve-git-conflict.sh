#!/bin/bash

# 解决Git冲突并更新到最新代码

set -e

echo "=========================================="
echo "解决Git冲突并更新代码"
echo "=========================================="
echo ""

cd ~/wcpay 2>/dev/null || {
    echo "✗ 找不到 ~/wcpay 目录"
    exit 1
}

# 检查是否有未提交的更改
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    echo "检测到本地更改..."
    echo ""
    
    # 显示更改的文件
    echo "更改的文件："
    git status --short
    echo ""
    
    echo "选择处理方式："
    echo "  1. 暂存本地更改（推荐，保留你的修改）"
    echo "  2. 放弃本地更改（使用远程版本）"
    echo ""
    read -p "请选择 (1/2，默认1): " choice
    
    choice=${choice:-1}
    
    if [ "$choice" = "2" ]; then
        echo ""
        echo "放弃本地更改..."
        git reset --hard HEAD
        git clean -fd
        echo "✓ 本地更改已放弃"
    else
        echo ""
        echo "暂存本地更改..."
        git stash push -m "Local changes before pull $(date +%Y%m%d-%H%M%S)"
        echo "✓ 更改已暂存"
        echo ""
        echo "提示: 如需恢复暂存的更改，运行: git stash pop"
    fi
    echo ""
fi

# 拉取最新代码
echo "拉取最新代码..."
git fetch origin main
git reset --hard origin/main

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ 代码已更新到最新版本"
    
    # 如果有暂存的更改，提示恢复
    if git stash list | grep -q "Local changes"; then
        echo ""
        echo "提示: 您有暂存的本地更改"
        echo "查看: git stash list"
        echo "恢复: git stash pop"
    fi
else
    echo ""
    echo "✗ 更新失败"
    exit 1
fi

echo ""
echo "=========================================="
echo "完成！"
echo "=========================================="
echo ""

