#!/bin/bash

# 快速启动Ubuntu环境并进入项目目录的助手脚本
# 在Mac终端中运行此脚本

PROJECT_DIR="/Users/michael/Desktop/woocommerce-pay-20251122"

echo "=========================================="
echo "快速启动 OrbStack Ubuntu 环境"
echo "=========================================="
echo ""

# 检查OrbStack是否安装
if ! command -v orbstack &> /dev/null; then
    echo "⚠ OrbStack未安装或不在PATH中"
    echo ""
    echo "请先安装OrbStack:"
    echo "  https://orbstack.dev/"
    exit 1
fi

echo "步骤1: 检查Ubuntu实例..."
if orbstack list 2>/dev/null | grep -q ubuntu; then
    echo "  ✓ 找到Ubuntu实例"
else
    echo "  ⚠ 未找到Ubuntu实例"
    echo ""
    read -p "是否创建新的Ubuntu实例？(y/n): " create_instance
    if [ "$create_instance" = "y" ] || [ "$create_instance" = "Y" ]; then
        echo "  创建Ubuntu实例..."
        orbstack create ubuntu:22.04 || {
            echo "  ✗ 创建失败，请手动在OrbStack UI中创建"
            exit 1
        }
    fi
fi

echo ""
echo "步骤2: 准备进入Ubuntu环境..."
echo ""
echo "接下来将："
echo "  1. 进入Ubuntu环境"
echo "  2. 检查项目文件"
echo "  3. 运行协助脚本"
echo ""

read -p "是否继续？(y/n): " proceed
if [ "$proceed" != "y" ] && [ "$proceed" != "Y" ]; then
    echo "已取消"
    exit 0
fi

echo ""
echo "正在进入Ubuntu环境..."
echo "=========================================="
echo ""

# 进入Ubuntu并执行命令
orbstack shell ubuntu << 'EOF'
echo ""
echo "已进入Ubuntu环境"
echo ""

# 检查项目目录
PROJECT_PATHS=(
    "/mnt/Users/michael/Desktop/woocommerce-pay-20251122"
    "/host/Users/michael/Desktop/woocommerce-pay-20251122"
    "$HOME/woocommerce-pay-20251122"
    "$HOME/wcpay"
)

PROJECT_DIR=""
for path in "${PROJECT_PATHS[@]}"; do
    if [ -d "$path" ]; then
        PROJECT_DIR="$path"
        echo "✓ 找到项目目录: $PROJECT_DIR"
        break
    fi
done

if [ -z "$PROJECT_DIR" ]; then
    echo "⚠ 未找到项目目录"
    echo ""
    echo "请选择："
    echo "1. 使用git克隆项目"
    echo "2. 手动指定项目路径"
    read -p "选择 (1/2): " choice
    
    if [ "$choice" = "1" ]; then
        cd ~
        read -p "输入git仓库URL (或按Enter使用默认): " repo_url
        repo_url=${repo_url:-"https://github.com/owenhhs/wcpay.git"}
        git clone "$repo_url" wcpay
        cd wcpay
        PROJECT_DIR="$PWD"
    else
        read -p "请输入项目目录路径: " PROJECT_DIR
        cd "$PROJECT_DIR"
    fi
else
    cd "$PROJECT_DIR"
fi

echo ""
echo "当前目录: $(pwd)"
echo ""

# 检查脚本文件
if [ -f "scripts/assist-test.sh" ]; then
    echo "✓ 找到协助脚本"
    echo ""
    echo "运行协助脚本..."
    echo "=========================================="
    echo ""
    chmod +x scripts/*.sh
    bash scripts/assist-test.sh
else
    echo "✗ 未找到协助脚本"
    echo ""
    echo "请检查项目目录是否正确"
    echo "当前目录内容:"
    ls -la
fi
EOF

echo ""
echo "=========================================="
echo "已退出Ubuntu环境"
echo "=========================================="

