#!/bin/bash

# 启动开发环境脚本
# 自动检测环境并选择最佳方案

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

echo "=========================================="
echo "启动开发环境"
echo "=========================================="

# 检查Docker是否可用
if command -v docker &> /dev/null && docker info &> /dev/null; then
    echo "✓ Docker可用"
    
    # 尝试启动Docker环境
    echo ""
    echo "尝试启动Docker Compose环境..."
    
    # 检查镜像是否存在
    if docker images | grep -q wordpress:latest || docker pull wordpress:latest 2>/dev/null; then
        echo "✓ WordPress镜像可用"
    else
        echo "⚠ 无法拉取镜像，网络可能有问题"
        echo ""
        echo "请选择："
        echo "1. 继续尝试启动（使用已有镜像）"
        echo "2. 使用本地安装方式（推荐）"
        read -p "选择 (1/2): " choice
        if [ "$choice" != "1" ]; then
            echo ""
            echo "请参考以下文档进行本地安装："
            echo "  docs/ORBSTACK_SETUP.md"
            echo ""
            exit 0
        fi
    fi
    
    # 启动Docker Compose
    echo ""
    echo "启动Docker Compose服务..."
    docker-compose -f scripts/docker-compose.yml up -d
    
    # 等待服务启动
    echo "等待服务启动..."
    sleep 10
    
    # 检查服务状态
    if docker ps | grep -q wp-dev; then
        echo "✓ WordPress容器运行中"
        
        # 等待WordPress就绪
        echo "等待WordPress就绪..."
        for i in {1..30}; do
            if docker exec wp-dev wp core version --allow-root &>/dev/null; then
                echo "✓ WordPress已就绪"
                break
            fi
            sleep 2
        done
        
        # 检查WordPress是否已安装
        if ! docker exec wp-dev wp core is-installed --allow-root 2>/dev/null; then
            echo ""
            echo "安装WordPress..."
            docker exec wp-dev wp core install \
                --url=http://localhost:8080 \
                --title="WooCommerce Dev" \
                --admin_user=admin \
                --admin_password=admin123 \
                --admin_email=admin@example.com \
                --allow-root 2>/dev/null || echo "WordPress可能已安装"
        fi
        
        # 检查WooCommerce
        if ! docker exec wp-dev wp plugin is-installed woocommerce --allow-root 2>/dev/null; then
            echo "安装WooCommerce..."
            docker exec wp-dev wp plugin install woocommerce --activate --allow-root
        fi
        
        # 安装主题
        if ! docker exec wp-dev wp theme is-installed storefront --allow-root 2>/dev/null; then
            echo "安装Storefront主题..."
            docker exec wp-dev wp theme install storefront --activate --allow-root
        fi
        
        # 激活插件
        echo "激活支付插件..."
        docker exec wp-dev wp plugin activate woocommerce-pay --allow-root 2>/dev/null || echo "插件可能需要手动激活"
        
        echo ""
        echo "=========================================="
        echo "环境启动完成！"
        echo "=========================================="
        echo ""
        echo "访问地址："
        echo "  WordPress: http://localhost:8080"
        echo "  管理后台: http://localhost:8080/wp-admin"
        echo "    用户名: admin"
        echo "    密码: admin123"
        echo "  phpMyAdmin: http://localhost:8081"
        echo ""
        echo "查看日志："
        echo "  docker-compose -f scripts/docker-compose.yml logs -f"
        echo ""
        echo "停止服务："
        echo "  docker-compose -f scripts/docker-compose.yml down"
        echo ""
        
    else
        echo "✗ 容器启动失败"
        echo ""
        echo "请查看日志："
        echo "  docker-compose -f scripts/docker-compose.yml logs"
        echo ""
        exit 1
    fi
    
else
    echo "✗ Docker不可用"
    echo ""
    echo "请使用本地安装方式，参考文档："
    echo "  docs/ORBSTACK_SETUP.md"
    echo ""
    exit 1
fi

