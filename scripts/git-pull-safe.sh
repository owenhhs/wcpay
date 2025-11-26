#!/bin/bash

# 安全地拉取代码更新

echo "=========================================="
echo "安全拉取代码更新"
echo "=========================================="
echo ""

cd ~/wcpay 2>/dev/null || {
    echo "✗ 找不到 ~/wcpay 目录"
    exit 1
}

# 检查是否有未提交的更改
if [ -n "$(git status --porcelain)" ]; then
    echo "检测到本地更改，正在处理..."
    echo ""
    
    # 显示更改
    echo "当前更改："
    git status --short
    echo ""
    
    # 询问是否保留（这里自动选择stash）
    echo "选项:"
    echo "  1. 暂存更改并更新（保留本地更改）"
    echo "  2. 放弃本地更改并更新"
    echo ""
    
    # 自动选择暂存（最安全）
    echo "→ 选择: 暂存更改并更新（推荐）"
    echo ""
    
    # 暂存更改
    echo "暂存本地更改..."
    git stash push -m "Local changes before pull $(date +%Y%m%d-%H%M%S)"
    
    if [ $? -eq 0 ]; then
        echo "✓ 更改已暂存"
    else
        echo "✗ 暂存失败"
        exit 1
    fi
    echo ""
fi

# 拉取更新
echo "拉取最新代码..."
git pull origin main

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ 代码已更新"
    
    # 如果有暂存的更改，提示恢复
    if git stash list | grep -q "Local changes"; then
        echo ""
        echo "提示: 您有暂存的本地更改"
        echo "如果需要恢复: git stash pop"
    fi
else
    echo ""
    echo "✗ 更新失败"
    exit 1
fi

echo ""
echo "=========================================="

