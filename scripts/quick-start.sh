#!/bin/bash

# 快速启动开发环境的简化脚本
# 适用于已有Ubuntu实例的情况

set -e

echo "=========================================="
echo "快速开发环境设置"
echo "=========================================="

# 检查是否在Ubuntu环境中
if [ ! -f /etc/os-release ]; then
    echo "错误: 此脚本需要在Ubuntu环境中运行"
    exit 1
fi

echo ""
echo "选择部署方式:"
echo "1. Docker Compose (需要网络连接)"
echo "2. 本地安装 (推荐，不依赖网络)"
echo ""
read -p "请选择 (1/2): " choice

case $choice in
    1)
        echo "使用Docker Compose方式..."
        if command -v docker-compose &> /dev/null || command -v docker &> /dev/null; then
            cd "$(dirname "$0")/.."
            docker-compose -f scripts/docker-compose.yml up -d || {
                echo "Docker启动失败，尝试本地安装方式..."
                echo "请手动运行: bash scripts/dev-setup.sh"
            }
        else
            echo "Docker未安装，请先安装Docker或使用本地安装方式"
        fi
        ;;
    2)
        echo "使用本地安装方式..."
        echo "请确保有sudo权限，然后运行:"
        echo "  sudo bash scripts/dev-setup.sh"
        ;;
    *)
        echo "无效选择"
        exit 1
        ;;
esac

