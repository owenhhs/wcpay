#!/bin/bash

# 在Ubuntu环境中运行的完整设置脚本
# 如果项目文件不存在，此脚本会引导您创建或获取

set -e

echo "=========================================="
echo "Ubuntu环境完整设置"
echo "=========================================="
echo ""

# 检查当前位置
echo "当前目录: $(pwd)"
echo ""

# 检查是否有scripts目录
if [ -d "scripts" ] && [ -f "scripts/assist-test.sh" ]; then
    echo "✓ 项目文件已存在"
    cd "$(dirname "$0")/.." 2>/dev/null || cd ~/wcpay
else
    echo "⚠ 项目文件不存在"
    echo ""
    echo "请选择："
    echo "1. 从GitHub克隆（需要网络）"
    echo "2. 使用OrbStack文件共享（从Mac复制）"
    echo "3. 手动创建目录结构"
    read -p "选择 (1/2/3): " choice
    
    case $choice in
        1)
            echo ""
            echo "安装git..."
            sudo apt-get update -qq
            sudo apt-get install -y git curl wget -qq
            echo ""
            echo "从GitHub克隆项目..."
            cd ~
            git clone https://github.com/owenhhs/wcpay.git || {
                echo "克隆失败，可能是仓库为空或网络问题"
                echo "请先确保代码已推送到GitHub"
                exit 1
            }
            cd wcpay
            ;;
        2)
            echo ""
            echo "查找共享文件夹..."
            SHARED_PATHS=(
                "/mnt/Users/michael/Desktop/woocommerce-pay-20251122"
                "/host/Users/michael/Desktop/woocommerce-pay-20251122"
                "/Volumes/Users/michael/Desktop/woocommerce-pay-20251122"
            )
            
            FOUND=0
            for path in "${SHARED_PATHS[@]}"; do
                if [ -d "$path" ]; then
                    echo "✓ 找到: $path"
                    cd "$path"
                    FOUND=1
                    break
                fi
            done
            
            if [ $FOUND -eq 0 ]; then
                echo "✗ 未找到共享文件夹"
                echo ""
                echo "请检查OrbStack文件共享设置，或手动复制项目文件"
                exit 1
            fi
            ;;
        3)
            echo ""
            echo "手动创建需要完整的项目文件"
            echo "建议使用方法1或2"
            exit 1
            ;;
    esac
fi

# 验证项目文件
if [ ! -d "scripts" ]; then
    echo "✗ scripts目录不存在"
    echo "当前目录内容:"
    ls -la
    exit 1
fi

echo ""
echo "✓ 项目文件验证通过"
echo ""

# 设置权限
echo "设置脚本权限..."
chmod +x scripts/*.sh
echo "✓ 权限设置完成"
echo ""

# 运行协助脚本
echo "=========================================="
echo "运行协助脚本"
echo "=========================================="
echo ""

bash scripts/assist-test.sh

