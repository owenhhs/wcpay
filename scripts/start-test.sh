#!/bin/bash

# 简化的启动脚本 - 直接进入Ubuntu并运行测试

echo "=========================================="
echo "启动测试环境"
echo "=========================================="
echo ""

# 检查是否在Ubuntu环境中
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "✓ 已在 $NAME 环境中"
    echo ""
    
    # 检查项目目录
    PROJECT_DIRS=(
        "/mnt/Users/michael/Desktop/woocommerce-pay-20251122"
        "/host/Users/michael/Desktop/woocommerce-pay-20251122"
        "$HOME/woocommerce-pay-20251122"
        "$HOME/wcpay"
        "$(pwd)"
    )
    
    for dir in "${PROJECT_DIRS[@]}"; do
        if [ -d "$dir" ] && [ -f "$dir/scripts/assist-test.sh" ]; then
            echo "✓ 找到项目目录: $dir"
            cd "$dir"
            break
        fi
    done
    
    if [ -f "scripts/assist-test.sh" ]; then
        echo ""
        echo "运行协助脚本..."
        echo "=========================================="
        echo ""
        bash scripts/assist-test.sh
    else
        echo "✗ 未找到项目目录"
        echo ""
        echo "当前目录: $(pwd)"
        echo "请进入项目目录后运行此脚本"
    fi
else
    echo "⚠ 当前不在Ubuntu环境中"
    echo ""
    echo "请在Ubuntu环境中运行此脚本"
    echo ""
    echo "方法1: 使用OrbStack UI"
    echo "  1. 打开OrbStack应用"
    echo "  2. 启动Ubuntu实例"
    echo "  3. 在终端中运行此脚本"
    echo ""
    echo "方法2: 使用命令行"
    echo "  如果OrbStack已安装，尝试："
    echo "    orbstack shell ubuntu"
    echo "  或"
    echo "    docker run -it ubuntu:22.04 bash"
    echo ""
fi

