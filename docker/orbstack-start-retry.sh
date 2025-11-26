#!/bin/bash

# 带重试机制的Docker启动脚本

set -e

echo "=========================================="
echo "启动Docker WordPress环境（带重试）"
echo "=========================================="
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_DIR"

# 检查Docker
if ! command -v docker &> /dev/null; then
    echo "✗ Docker未安装"
    echo "请先运行: bash docker/install-docker-orbstack.sh"
    exit 1
fi

# 检查docker-compose
COMPOSE_CMD=""
if docker compose version &> /dev/null 2>/dev/null; then
    COMPOSE_CMD="docker compose"
elif command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
else
    echo "✗ docker-compose未安装"
    echo "正在尝试安装..."
    
    if bash "$SCRIPT_DIR/check-docker-compose.sh"; then
        if docker compose version &> /dev/null 2>/dev/null; then
            COMPOSE_CMD="docker compose"
        elif command -v docker-compose &> /dev/null; then
            COMPOSE_CMD="docker-compose"
        else
            echo "✗ 安装失败，请手动安装: bash docker/check-docker-compose.sh"
            exit 1
        fi
    else
        echo "✗ 安装失败"
        exit 1
    fi
fi

# 检查是否需要sudo
if docker ps >/dev/null 2>&1; then
    DOCKER_SUDO=""
else
    DOCKER_SUDO="sudo"
fi

# 选择配置文件
COMPOSE_FILE="docker-compose.yml"
if [ ! -f "$COMPOSE_FILE" ] || [ -f "docker-compose-simple.yml" ]; then
    echo "使用简化版配置（不包含phpMyAdmin）..."
    COMPOSE_FILE="docker-compose-simple.yml"
fi

echo "使用配置文件: $COMPOSE_FILE"
echo ""

# 函数：拉取镜像（带重试）
pull_image_with_retry() {
    local image=$1
    local max_attempts=3
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        echo "尝试拉取镜像: $image (第 $attempt/$max_attempts 次)..."
        if $DOCKER_SUDO docker pull "$image" 2>&1 | grep -q "Error\|timeout\|TLS handshake"; then
            echo "  ⚠️  拉取失败，等待5秒后重试..."
            sleep 5
            attempt=$((attempt + 1))
        else
            echo "  ✓ 镜像拉取成功"
            return 0
        fi
    done
    
    echo "  ✗ 镜像拉取失败，已重试 $max_attempts 次"
    return 1
}

# 步骤1: 拉取必要镜像
echo "[1/3] 拉取Docker镜像..."
echo ""

# WordPress镜像
if ! pull_image_with_retry "wordpress:latest"; then
    echo ""
    echo "⚠️  WordPress镜像拉取失败，但继续尝试..."
fi

# MySQL镜像
if ! pull_image_with_retry "mysql:8.0"; then
    echo ""
    echo "⚠️  MySQL镜像拉取失败"
    echo "尝试使用MariaDB（兼容MySQL，镜像更小）..."
    
    if pull_image_with_retry "mariadb:latest"; then
        echo ""
        echo "✓ 使用MariaDB替代MySQL"
        COMPOSE_FILE="docker-compose-alternative.yml"
        if [ ! -f "$COMPOSE_FILE" ]; then
            echo "  ⚠️  替代配置文件不存在，尝试继续使用原配置..."
            COMPOSE_FILE="docker-compose-simple.yml"
        fi
    else
        echo ""
        echo "✗ 数据库镜像拉取失败"
        echo ""
        echo "请手动拉取镜像或使用镜像加速器："
        echo "  bash docker/pull-images-with-retry.sh"
        exit 1
    fi
fi

# phpMyAdmin镜像（仅完整版配置需要）
if [ "$COMPOSE_FILE" = "docker-compose.yml" ]; then
    if ! pull_image_with_retry "phpmyadmin:latest"; then
        echo ""
        echo "⚠️  phpMyAdmin镜像拉取失败"
        echo "   切换到简化版配置..."
        COMPOSE_FILE="docker-compose-simple.yml"
    fi
fi

echo ""
echo "[2/3] 启动Docker容器..."

# 停止现有容器
$DOCKER_SUDO $COMPOSE_CMD -f "$COMPOSE_FILE" down 2>/dev/null || true

# 启动容器
if $DOCKER_SUDO $COMPOSE_CMD -f "$COMPOSE_FILE" up -d; then
    echo "✓ 容器启动成功"
else
    echo "✗ 容器启动失败"
    echo ""
    echo "尝试使用简化版配置..."
    if [ "$COMPOSE_FILE" != "docker-compose-simple.yml" ] && [ -f "docker-compose-simple.yml" ]; then
        COMPOSE_FILE="docker-compose-simple.yml"
        $DOCKER_SUDO $COMPOSE_CMD -f "$COMPOSE_FILE" up -d
    else
        exit 1
    fi
fi

echo ""
echo "[3/3] 等待服务启动..."
sleep 5

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
echo ""
echo "  方式1: 从Ubuntu内部访问"
echo "    WordPress: http://localhost:8080"
if [ "$COMPOSE_FILE" = "docker-compose.yml" ]; then
    echo "    phpMyAdmin: http://localhost:8081"
fi
echo ""
echo "  方式2: 从Mac/Windows访问"
echo "    获取Ubuntu IP: $IP"
echo "    WordPress: http://$IP:8080"
if [ "$COMPOSE_FILE" = "docker-compose.yml" ]; then
    echo "    phpMyAdmin: http://$IP:8081"
fi
echo ""

if [ "$COMPOSE_FILE" = "docker-compose-simple.yml" ]; then
    echo "ℹ️  当前使用简化版配置（不包含phpMyAdmin）"
    echo "   可以使用命令行访问数据库："
    echo "   docker exec -it wp-dev-db mysql -u wpuser -pwppass123 wordpress"
    echo ""
fi

echo "📋 下一步："
echo "  配置WordPress: bash docker/docker-setup.sh"
echo ""

