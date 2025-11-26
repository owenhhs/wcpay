#!/bin/bash

# 一键修复Git冲突并继续WordPress安装

set -e

echo "=========================================="
echo "修复Git冲突并继续安装"
echo "=========================================="
echo ""

cd ~/wcpay 2>/dev/null || {
    echo "✗ 找不到 ~/wcpay 目录"
    exit 1
}

# 步骤1: 处理Git更改
echo "[1/4] 处理Git更改..."
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    echo "  暂存本地更改..."
    git stash push -m "Auto-stash $(date +%Y%m%d-%H%M%S)" 2>/dev/null || true
fi

# 拉取更新
echo "  拉取最新代码..."
git pull origin main || {
    echo "  ⚠ 拉取失败，使用强制覆盖..."
    git fetch origin main
    git reset --hard origin/main
}

echo "✓ 代码已更新"
echo ""

# 步骤2: 设置权限
echo "[2/4] 设置脚本权限..."
chmod +x scripts/*.sh 2>/dev/null || true
echo "✓ 权限已设置"
echo ""

# 步骤3: 修复Nginx
echo "[3/4] 修复Nginx配置..."
sudo bash scripts/fix-nginx.sh
echo ""

# 步骤4: 安装WordPress
echo "[4/4] 安装WordPress..."
sudo bash scripts/install-wordpress-cli.sh
echo ""

echo "=========================================="
echo "完成！"
echo "=========================================="

