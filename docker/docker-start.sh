#!/bin/bash

# Docker开发环境启动脚本

set -e

echo "=========================================="
echo "启动Docker开发环境"
echo "=========================================="
echo ""

# 检查Docker是否运行
if ! docker info >/dev/null 2>&1; then
    echo "✗ Docker未运行，请启动Docker"
    exit 1
fi

# 检查docker-compose
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "✗ docker-compose未安装"
    exit 1
fi

# 使用docker compose或docker-compose
if docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    COMPOSE_CMD="docker-compose"
fi

echo "[1/4] 检查并创建必要的目录..."
mkdir -p docker
mkdir -p wp-content/plugins/woocommerce-pay

echo "✓ 目录已创建"
echo ""

echo "[2/4] 启动Docker容器..."
$COMPOSE_CMD up -d

echo ""
echo "[3/4] 等待服务启动..."
sleep 10

# 检查容器状态
echo ""
echo "[4/4] 检查容器状态..."
$COMPOSE_CMD ps

echo ""
echo "=========================================="
echo "Docker环境已启动！"
echo "=========================================="
echo ""
echo "📍 访问地址："
echo "  WordPress: http://localhost:8080"
echo "  phpMyAdmin: http://localhost:8081"
echo ""
echo "📋 下一步："
echo "  1. 访问 http://localhost:8080 完成WordPress安装"
echo "  2. 安装WooCommerce插件"
echo "  3. 激活支付插件"
echo ""
echo "🔧 常用命令："
echo "  查看日志: $COMPOSE_CMD logs -f"
echo "  停止服务: $COMPOSE_CMD down"
echo "  重启服务: $COMPOSE_CMD restart"
echo "  进入WordPress容器: docker exec -it wp-dev-wordpress bash"
echo ""

