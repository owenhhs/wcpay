#!/bin/bash

# 修复网络问题并启动Docker环境

set -e

echo "=========================================="
echo "修复网络问题并启动Docker环境"
echo "=========================================="
echo ""

cd ~/wcpay 2>/dev/null || {
    echo "✗ 找不到 ~/wcpay 目录"
    exit 1
}

# 步骤1: 配置镜像加速器
echo "[1/4] 配置Docker镜像加速器..."
bash docker/fix-docker-network.sh >/dev/null 2>&1 || true

# 重启Docker服务
echo "  重启Docker服务..."
sudo systemctl restart docker 2>/dev/null || sudo service docker restart 2>/dev/null || true
sleep 3
echo "✓ Docker服务已重启"
echo ""

# 步骤2: 拉取镜像
echo "[2/4] 拉取Docker镜像..."
if bash docker/pull-images-with-retry.sh; then
    echo "✓ 镜像拉取成功"
else
    echo ""
    echo "⚠️  镜像拉取部分失败，尝试使用替代方案..."
    echo ""
    
    # 尝试使用MariaDB替代
    if docker pull mariadb:latest 2>/dev/null; then
        echo "✓ MariaDB镜像拉取成功，使用替代配置"
        COMPOSE_FILE="docker-compose-alternative.yml"
    else
        echo "✗ 无法拉取数据库镜像"
        echo ""
        echo "请稍后重试或检查网络连接"
        exit 1
    fi
fi
echo ""

# 步骤3: 启动容器
echo "[3/4] 启动Docker容器..."
COMPOSE_FILE=${COMPOSE_FILE:-"docker-compose-simple.yml"}

# 检查docker-compose命令
if docker compose version &> /dev/null 2>/dev/null; then
    COMPOSE_CMD="docker compose"
elif command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
else
    echo "✗ docker-compose未安装"
    echo "请先运行: bash docker/check-docker-compose.sh"
    exit 1
fi

if docker ps >/dev/null 2>&1; then
    DOCKER_SUDO=""
else
    DOCKER_SUDO="sudo"
fi

echo "  使用配置文件: $COMPOSE_FILE"
$DOCKER_SUDO $COMPOSE_CMD -f "$COMPOSE_FILE" down 2>/dev/null || true
$DOCKER_SUDO $COMPOSE_CMD -f "$COMPOSE_FILE" up -d

if [ $? -eq 0 ]; then
    echo "✓ 容器启动成功"
else
    echo "✗ 容器启动失败"
    exit 1
fi
echo ""

# 步骤4: 等待服务启动
echo "[4/4] 等待服务启动..."
sleep 10

# 检查容器状态
echo ""
echo "容器状态："
$DOCKER_SUDO $COMPOSE_CMD -f "$COMPOSE_FILE" ps

# 获取IP地址
IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")

echo ""
echo "=========================================="
echo "Docker环境已启动！"
echo "=========================================="
echo ""
echo "📍 访问地址："
echo "  WordPress: http://localhost:8080"
echo "  从Mac访问: http://$IP:8080"
echo ""
echo "📋 下一步："
echo "  配置WordPress: bash docker/docker-setup.sh"
echo ""

