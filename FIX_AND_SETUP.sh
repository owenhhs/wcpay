#!/bin/bash

# 在Ubuntu环境中运行此脚本 - 自动修复和设置

echo "=========================================="
echo "Ubuntu环境修复和设置"
echo "=========================================="
echo ""

# 检查当前目录
echo "当前目录: $(pwd)"
echo ""

# 步骤1: 安装必要工具
echo "[1/4] 安装必要工具..."
sudo apt-get update -qq
sudo apt-get install -y -qq git curl wget unzip >/dev/null 2>&1
echo "✓ 工具安装完成"
echo ""

# 步骤2: 查找项目目录
echo "[2/4] 查找项目目录..."
PROJECT_DIR=""

# 尝试几个可能的位置
POSSIBLE_PATHS=(
    "/mnt/Users/michael/Desktop/woocommerce-pay-20251122"
    "/host/Users/michael/Desktop/woocommerce-pay-20251122"
    "$HOME/woocommerce-pay-20251122"
    "$HOME/wcpay"
    "/workspace"
)

for path in "${POSSIBLE_PATHS[@]}"; do
    if [ -d "$path" ] && [ -f "$path/scripts/assist-test.sh" ]; then
        PROJECT_DIR="$path"
        echo "✓ 找到项目目录: $PROJECT_DIR"
        break
    fi
done

# 如果没找到，尝试克隆
if [ -z "$PROJECT_DIR" ]; then
    echo "未找到项目目录，准备从GitHub克隆..."
    cd ~
    echo ""
    echo "正在克隆项目..."
    git clone https://github.com/owenhhs/wcpay.git 2>&1 || {
        echo "克隆失败，请检查网络连接"
        echo ""
        echo "或者您可以："
        echo "1. 使用OrbStack的文件共享功能复制项目"
        echo "2. 手动复制项目文件到当前目录"
        exit 1
    }
    
    if [ -d "wcpay" ]; then
        PROJECT_DIR="$HOME/wcpay"
        echo "✓ 项目已克隆到: $PROJECT_DIR"
    fi
fi

if [ -z "$PROJECT_DIR" ] || [ ! -d "$PROJECT_DIR" ]; then
    echo "✗ 无法找到或创建项目目录"
    exit 1
fi

cd "$PROJECT_DIR"
echo ""
echo "当前工作目录: $(pwd)"
echo ""

# 步骤3: 检查脚本文件
echo "[3/4] 检查脚本文件..."
if [ ! -d "scripts" ]; then
    echo "✗ scripts目录不存在"
    echo "当前目录内容:"
    ls -la
    exit 1
fi

if [ ! -f "scripts/assist-test.sh" ]; then
    echo "✗ assist-test.sh不存在"
    echo "scripts目录内容:"
    ls -la scripts/
    exit 1
fi

echo "✓ 脚本文件存在"
echo ""

# 步骤4: 设置权限并运行
echo "[4/4] 设置权限..."
chmod +x scripts/*.sh
echo "✓ 权限设置完成"
echo ""

echo "=========================================="
echo "环境准备完成！"
echo "=========================================="
echo ""
echo "项目目录: $PROJECT_DIR"
echo ""
echo "现在运行协助脚本..."
echo "=========================================="
echo ""

bash scripts/assist-test.sh

