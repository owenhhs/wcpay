#!/bin/bash

# 检查docker-compose并安装

set -e

echo "=========================================="
echo "检查docker-compose"
echo "=========================================="
echo ""

# 检查新版本 docker compose (V2)
if docker compose version &> /dev/null 2>/dev/null; then
    echo "✓ docker compose (V2) 已安装"
    docker compose version
    echo ""
    echo "使用命令: docker compose"
    exit 0
fi

# 检查旧版本 docker-compose
if command -v docker-compose &> /dev/null; then
    echo "✓ docker-compose (V1) 已安装"
    docker-compose --version
    echo ""
    echo "使用命令: docker-compose"
    exit 0
fi

# 都没有，需要安装
echo "✗ docker-compose 未安装"
echo ""
echo "正在安装..."

SUDO=""
if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
fi

# 方法1: 尝试安装docker-compose-plugin (V2)
echo "[方法1] 尝试安装 docker-compose-plugin (V2)..."
$SUDO apt-get update -qq >/dev/null 2>&1
$SUDO apt-get install -y -qq docker-compose-plugin >/dev/null 2>&1 && {
    if docker compose version &> /dev/null 2>/dev/null; then
        echo "✓ docker compose (V2) 安装成功"
        docker compose version
        exit 0
    fi
}

# 方法2: 尝试安装docker-compose (V1)
echo "[方法2] 尝试安装 docker-compose (V1)..."
$SUDO apt-get install -y -qq docker-compose >/dev/null 2>&1 && {
    if command -v docker-compose &> /dev/null; then
        echo "✓ docker-compose (V1) 安装成功"
        docker-compose --version
        exit 0
    fi
}

# 方法3: 使用pip安装
echo "[方法3] 尝试使用pip安装..."
if command -v pip3 &> /dev/null; then
    $SUDO pip3 install docker-compose >/dev/null 2>&1 && {
        if command -v docker-compose &> /dev/null; then
            echo "✓ docker-compose (pip安装) 成功"
            docker-compose --version
            exit 0
        fi
    }
fi

# 方法4: 下载二进制文件
echo "[方法4] 下载docker-compose二进制文件..."
COMPOSE_VERSION="v2.23.0"
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    ARCH="x86_64"
elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    ARCH="aarch64"
else
    ARCH="x86_64"
fi

DOCKER_COMPOSE_URL="https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-${ARCH}"

echo "  从GitHub下载: ${COMPOSE_VERSION}"
cd /tmp
curl -L "$DOCKER_COMPOSE_URL" -o docker-compose 2>/dev/null || \
    wget -q "$DOCKER_COMPOSE_URL" -O docker-compose || {
    echo "  ✗ 下载失败，尝试安装docker-compose-plugin..."
    
    # 最后尝试：安装compose plugin
    $SUDO apt-get install -y docker-compose-plugin || {
        echo ""
        echo "=========================================="
        echo "安装失败"
        echo "=========================================="
        echo ""
        echo "请手动安装docker-compose："
        echo ""
        echo "方法1: 安装docker-compose-plugin"
        echo "  sudo apt-get update"
        echo "  sudo apt-get install docker-compose-plugin"
        echo ""
        echo "方法2: 使用pip安装"
        echo "  sudo apt-get install python3-pip"
        echo "  sudo pip3 install docker-compose"
        echo ""
        echo "方法3: 下载二进制文件"
        echo "  sudo curl -L \"https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose"
        echo "  sudo chmod +x /usr/local/bin/docker-compose"
        exit 1
    }
}

if [ -f docker-compose ]; then
    $SUDO mv docker-compose /usr/local/bin/docker-compose
    $SUDO chmod +x /usr/local/bin/docker-compose
    
    if docker-compose --version >/dev/null 2>&1; then
        echo "✓ docker-compose 安装成功"
        docker-compose --version
        exit 0
    fi
fi

echo ""
echo "=========================================="
echo "安装完成，请测试："
echo "=========================================="
echo ""
echo "测试V2版本:"
echo "  docker compose version"
echo ""
echo "测试V1版本:"
echo "  docker-compose --version"
echo ""

