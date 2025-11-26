#!/bin/bash

# 检查环境并给出指导

echo "=========================================="
echo "环境检查和指导"
echo "=========================================="
echo ""

# 检查当前环境
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "✓ 当前运行在: $NAME $VERSION"
    echo ""
    
    # 检查WordPress
    if [ -d "/var/www/wordpress" ] || [ -d "/var/www/html" ]; then
        echo "✓ WordPress目录存在"
        echo ""
        echo "现在可以运行测试脚本："
        echo "  bash scripts/assist-test.sh"
        echo ""
    else
        echo "⚠ WordPress未安装"
        echo ""
        echo "建议运行："
        echo "  sudo bash scripts/setup-orbstack.sh"
        echo ""
    fi
else
    echo "⚠ 当前不在Linux/Ubuntu环境中"
    echo ""
    echo "您需要在OrbStack Ubuntu环境中运行脚本"
    echo ""
    echo "步骤："
    echo "  1. 打开新终端窗口"
    echo "  2. 运行: orbstack shell ubuntu"
    echo "  3. 进入项目目录"
    echo "  4. 运行: bash scripts/assist-test.sh"
    echo ""
    echo "或者我可以帮您创建一个快捷命令..."
fi

echo "=========================================="

