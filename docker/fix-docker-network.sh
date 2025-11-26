#!/bin/bash

# 修复Docker网络超时问题

set -e

echo "=========================================="
echo "修复Docker网络超时问题"
echo "=========================================="
echo ""

# 检查Docker是否运行
if ! docker ps >/dev/null 2>&1 && ! sudo docker ps >/dev/null 2>&1; then
    echo "✗ Docker未运行，请先启动Docker"
    exit 1
fi

SUDO=""
if ! docker ps >/dev/null 2>&1; then
    SUDO="sudo"
fi

echo "[方案1] 配置Docker镜像加速器..."
echo ""

# 创建或更新Docker daemon配置
DAEMON_JSON="/etc/docker/daemon.json"
DAEMON_JSON_BACKUP="/etc/docker/daemon.json.backup.$(date +%Y%m%d-%H%M%S)"

if [ -f "$DAEMON_JSON" ]; then
    echo "备份现有配置..."
    $SUDO cp "$DAEMON_JSON" "$DAEMON_JSON_BACKUP"
fi

echo "配置镜像加速器..."
$SUDO mkdir -p /etc/docker

# 使用国内镜像源（适合中国用户）或Docker官方镜像
$SUDO tee "$DAEMON_JSON" > /dev/null << 'EOF'
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com"
  ],
  "max-concurrent-downloads": 10,
  "max-concurrent-uploads": 5,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

echo "✓ 镜像加速器已配置"
echo ""

echo "[方案2] 使用简化版docker-compose（不包含phpMyAdmin）..."
cd ~/wcpay 2>/dev/null || {
    echo "⚠️  请在项目目录中运行此脚本"
}

if [ -f "docker-compose-simple.yml" ]; then
    echo "✓ 简化版配置已存在"
    echo ""
    echo "可以使用简化版配置启动（不包含phpMyAdmin）："
    echo "  docker-compose -f docker-compose-simple.yml up -d"
else
    echo "⚠️  简化版配置不存在"
fi

echo ""
echo "=========================================="
echo "解决方案"
echo "=========================================="
echo ""

echo "方案1: 重启Docker服务并重试"
echo "  sudo systemctl restart docker"
echo "  cd ~/wcpay && docker-compose up -d"
echo ""

echo "方案2: 使用简化版配置（推荐，不包含phpMyAdmin）"
echo "  cd ~/wcpay"
echo "  docker-compose -f docker-compose-simple.yml up -d"
echo ""

echo "方案3: 分步拉取镜像"
echo "  docker pull wordpress:latest"
echo "  docker pull mysql:8.0"
echo "  # phpMyAdmin可选，如果超时可以跳过"
echo "  docker-compose up -d"
echo ""

echo "方案4: 使用代理（如果有）"
echo "  配置HTTP_PROXY和HTTPS_PROXY环境变量"
echo ""

echo "=========================================="
echo "推荐操作"
echo "=========================================="
echo ""
echo "1. 重启Docker服务"
echo "   sudo systemctl restart docker"
echo ""
echo "2. 使用简化版配置启动"
echo "   cd ~/wcpay"
echo "   docker-compose -f docker-compose-simple.yml up -d"
echo ""
echo "这样会启动WordPress和MySQL，但不包含phpMyAdmin"
echo "（phpMyAdmin是可选工具，可以通过命令行访问数据库）"
echo ""

