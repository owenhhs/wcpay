#!/bin/bash

# 带重试机制的镜像拉取脚本

set -e

echo "=========================================="
echo "拉取Docker镜像（带重试）"
echo "=========================================="
echo ""

SUDO=""
if ! docker ps >/dev/null 2>&1; then
    SUDO="sudo"
fi

# 重试函数
pull_image_with_retry() {
    local image=$1
    local max_attempts=5
    local attempt=1
    local wait_time=5
    
    while [ $attempt -le $max_attempts ]; do
        echo "[尝试 $attempt/$max_attempts] 拉取镜像: $image"
        
        if $SUDO docker pull "$image" 2>&1; then
            echo "  ✓ 镜像拉取成功: $image"
            return 0
        else
            if [ $attempt -lt $max_attempts ]; then
                echo "  ⚠️  拉取失败，等待 ${wait_time} 秒后重试..."
                sleep $wait_time
                wait_time=$((wait_time + 5))  # 每次等待时间增加
            fi
            attempt=$((attempt + 1))
        fi
    done
    
    echo "  ✗ 镜像拉取失败: $image (已重试 $max_attempts 次)"
    return 1
}

# 配置镜像加速器
configure_registry_mirrors() {
    echo "配置Docker镜像加速器..."
    
    DAEMON_JSON="/etc/docker/daemon.json"
    
    if [ ! -f "$DAEMON_JSON" ] || ! grep -q "registry-mirrors" "$DAEMON_JSON" 2>/dev/null; then
        echo "  添加镜像加速器配置..."
        $SUDO mkdir -p /etc/docker
        
        if [ -f "$DAEMON_JSON" ]; then
            $SUDO cp "$DAEMON_JSON" "$DAEMON_JSON.backup.$(date +%Y%m%d-%H%M%S)"
        fi
        
        $SUDO tee "$DAEMON_JSON" > /dev/null << 'EOF'
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com",
    "https://dockerproxy.com"
  ],
  "max-concurrent-downloads": 10,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF
        
        echo "  ✓ 镜像加速器已配置"
        echo "  重启Docker服务以应用更改..."
        $SUDO systemctl restart docker || $SUDO service docker restart || true
        sleep 3
        echo "  ✓ Docker服务已重启"
    else
        echo "  ✓ 镜像加速器已配置"
    fi
    echo ""
}

# 拉取镜像
echo "[步骤1] 配置镜像加速器..."
configure_registry_mirrors

echo "[步骤2] 拉取WordPress镜像..."
if ! pull_image_with_retry "wordpress:latest"; then
    echo "  ⚠️  WordPress镜像拉取失败，但继续..."
fi
echo ""

echo "[步骤3] 拉取MySQL镜像..."
if ! pull_image_with_retry "mysql:8.0"; then
    echo ""
    echo "  ⚠️  MySQL镜像拉取失败"
    echo ""
    echo "  尝试替代方案："
    echo "  1. 使用MySQL 5.7（较小）："
    echo "     docker pull mysql:5.7"
    echo ""
    echo "  2. 使用MariaDB（兼容MySQL）："
    echo "     docker pull mariadb:latest"
    echo ""
    echo "  3. 稍后重试（可能是网络临时问题）"
    exit 1
fi
echo ""

echo "=========================================="
echo "镜像拉取完成！"
echo "=========================================="
echo ""
echo "现在可以启动Docker环境："
echo "  cd ~/wcpay"
echo "  docker-compose -f docker-compose-simple.yml up -d"
echo "  或"
echo "  docker compose -f docker-compose-simple.yml up -d"
echo ""

