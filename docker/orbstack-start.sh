#!/bin/bash

# 在OrbStack Ubuntu中使用Docker启动WordPress环境

set -e

echo "=========================================="
echo "在OrbStack中启动Docker WordPress环境"
echo "=========================================="
echo ""

# 检查Docker是否安装
if ! command -v docker &> /dev/null; then
    echo "✗ Docker未安装"
    echo ""
    echo "请先安装Docker："
    echo "  cd ~/wcpay && bash docker/install-docker-orbstack.sh"
    exit 1
fi

# 检查docker-compose
if docker compose version &> /dev/null 2>/dev/null; then
    COMPOSE_CMD="docker compose"
elif command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
else
    echo "✗ docker-compose未安装"
    echo ""
    echo "请先安装docker-compose："
    echo "  cd ~/wcpay && bash docker/install-docker-orbstack.sh"
    exit 1
fi

# 切换到项目目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_DIR"

echo "[1/4] 检查项目文件..."
if [ ! -f "docker-compose.yml" ]; then
    echo "✗ docker-compose.yml 不存在"
    exit 1
fi
echo "✓ 项目文件完整"
echo ""

# 检查是否需要sudo
if docker ps >/dev/null 2>&1; then
    DOCKER_SUDO=""
else
    echo "需要sudo权限运行Docker..."
    DOCKER_SUDO="sudo"
fi

echo "[2/4] 检查Docker服务..."
if ! $DOCKER_SUDO docker ps >/dev/null 2>&1; then
    echo "  启动Docker服务..."
    sudo systemctl start docker || sudo service docker start || {
        echo "✗ 无法启动Docker服务"
        exit 1
    }
fi
echo "✓ Docker服务运行中"
echo ""

echo "[3/4] 启动Docker容器..."
$DOCKER_SUDO $COMPOSE_CMD up -d

if [ $? -ne 0 ]; then
    echo "✗ 容器启动失败"
    exit 1
fi

echo ""
echo "[4/4] 等待服务启动..."
sleep 5

# 检查容器状态
echo ""
echo "容器状态："
$DOCKER_SUDO $COMPOSE_CMD ps

# 获取Ubuntu IP地址
IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")

echo ""
echo "=========================================="
echo "Docker环境已启动！"
echo "=========================================="
echo ""
echo "📍 访问地址："
echo ""
echo "  方式1: 从Ubuntu内部访问"
echo "    WordPress: http://localhost:8080"
echo "    phpMyAdmin: http://localhost:8081"
echo ""
echo "  方式2: 从Mac/Windows访问（需要端口转发）"
echo "    获取Ubuntu IP: $IP"
echo "    WordPress: http://$IP:8080"
echo "    phpMyAdmin: http://$IP:8081"
echo ""
echo "📋 下一步："
echo ""
echo "1. 配置WordPress："
echo "   bash docker/docker-setup.sh"
echo ""
echo "2. 或通过浏览器访问完成安装"
echo ""
echo "🔧 常用命令："
echo "  查看日志: $DOCKER_SUDO $COMPOSE_CMD logs -f"
echo "  停止服务: $DOCKER_SUDO $COMPOSE_CMD down"
echo "  重启服务: $DOCKER_SUDO $COMPOSE_CMD restart"
echo "  进入容器: $DOCKER_SUDO docker exec -it wp-dev-wordpress bash"
echo ""

