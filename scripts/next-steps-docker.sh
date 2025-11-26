#!/bin/bash

# 下一步操作指南脚本

set -e

echo "=========================================="
echo "🚀 下一步操作指南"
echo "=========================================="
echo ""

cd ~/wcpay 2>/dev/null || {
    echo "✗ 找不到 ~/wcpay 目录"
    exit 1
}

# 步骤1: 检查Docker
echo "[检查] Docker状态..."
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    echo "  ✓ Docker已安装: $DOCKER_VERSION"
    
    if docker ps >/dev/null 2>&1; then
        echo "  ✓ Docker服务运行中"
        
        # 检查容器是否运行
        if docker ps | grep -q "wp-dev-wordpress"; then
            echo "  ✓ WordPress容器正在运行"
            WP_RUNNING=true
        else
            echo "  ⚠️  WordPress容器未运行"
            WP_RUNNING=false
        fi
    else
        echo "  ⚠️  Docker服务未运行"
        WP_RUNNING=false
    fi
else
    echo "  ✗ Docker未安装"
    WP_RUNNING=false
fi
echo ""

# 步骤2: 检查项目文件
echo "[检查] 项目文件..."
if [ -f "docker-compose.yml" ]; then
    echo "  ✓ docker-compose.yml存在"
else
    echo "  ✗ docker-compose.yml不存在"
fi

if [ -d "docker" ]; then
    echo "  ✓ docker目录存在"
else
    echo "  ✗ docker目录不存在"
fi
echo ""

# 显示下一步操作
echo "=========================================="
echo "📋 下一步操作"
echo "=========================================="
echo ""

if [ "$WP_RUNNING" = true ]; then
    IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
    
    echo "✅ Docker环境已运行！"
    echo ""
    echo "📍 访问地址："
    echo "  前台: http://localhost:8080"
    echo "  后台: http://localhost:8080/wp-admin"
    echo ""
    echo "  从Mac访问: http://$IP:8080"
    echo ""
    echo "📋 下一步："
    echo "  1. 访问WordPress完成安装"
    echo "  2. 配置WooCommerce"
    echo "  3. 激活支付插件"
    echo "  4. 配置支付网关"
    echo ""
    echo "运行配置脚本:"
    echo "  bash docker/docker-setup.sh"
else
    echo "需要先启动Docker环境"
    echo ""
    echo "步骤1: 安装Docker（如果还没安装）"
    echo "  bash docker/install-docker-orbstack.sh"
    echo ""
    echo "步骤2: 启动WordPress环境"
    echo "  bash docker/orbstack-start.sh"
    echo ""
    echo "步骤3: 配置WordPress"
    echo "  bash docker/docker-setup.sh"
fi

echo ""
echo "=========================================="
echo "📚 查看详细指南"
echo "=========================================="
echo ""
echo "  cat NEXT_STEPS_DOCKER.md"
echo "  cat docs/ORBSTACK_DOCKER.md"
echo ""

