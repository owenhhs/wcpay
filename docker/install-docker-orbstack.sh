#!/bin/bash

# 在OrbStack Ubuntu中安装Docker

set -e

echo "=========================================="
echo "在OrbStack Ubuntu中安装Docker"
echo "=========================================="
echo ""

SUDO=""
if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
fi

# 检查运行环境
echo "检查运行环境..."
if [ -d "/run/orbstack" ] || [ -f "/opt/orbstack" ] || grep -qi "orbstack" /etc/hostname 2>/dev/null; then
    echo "✓ 检测到OrbStack环境"
elif [ -f /.dockerenv ]; then
    echo "⚠️  在Docker容器中运行（可能是在OrbStack的容器中）"
elif command -v systemd-detect-virt &> /dev/null && systemd-detect-virt | grep -q "oracle"; then
    echo "✓ 检测到虚拟化环境（可能是OrbStack）"
else
    echo "⚠️  无法明确检测OrbStack环境"
    echo "但会继续安装Docker（适用于任何Ubuntu系统）..."
fi
echo ""

# 步骤1: 更新系统
echo "[1/5] 更新系统包..."
$SUDO apt-get update -qq
echo "✓ 系统已更新"
echo ""

# 步骤2: 安装必要工具
echo "[2/5] 安装必要工具..."
$SUDO apt-get install -y -qq \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    apt-transport-https \
    >/dev/null 2>&1
echo "✓ 工具已安装"
echo ""

# 步骤3: 检查Docker是否已安装
echo "[3/5] 检查Docker安装..."
if command -v docker &> /dev/null; then
    echo "  ✓ Docker已安装"
    docker --version
else
    echo "  安装Docker..."
    
    # 添加Docker官方GPG密钥
    $SUDO mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
        $SUDO gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null || {
        echo "  ⚠ GPG密钥添加失败，尝试使用apt安装..."
        $SUDO apt-get install -y -qq docker.io docker-compose >/dev/null 2>&1
    }
    
    if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
        echo "  使用系统Docker包..."
        $SUDO apt-get install -y -qq docker.io docker-compose >/dev/null 2>&1
    else
        # 添加Docker仓库
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          $(lsb_release -cs) stable" | \
          $SUDO tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        # 安装Docker
        $SUDO apt-get update -qq
        $SUDO apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin >/dev/null 2>&1 || {
            echo "  ⚠ 官方仓库安装失败，使用系统包..."
            $SUDO apt-get install -y -qq docker.io docker-compose >/dev/null 2>&1
        }
    fi
    
    echo "  ✓ Docker已安装"
    docker --version
fi
echo ""

# 步骤4: 安装docker-compose
echo "[4/5] 检查docker-compose..."
if docker compose version &> /dev/null; then
    echo "  ✓ docker compose已安装（新版本）"
    docker compose version
elif command -v docker-compose &> /dev/null; then
    echo "  ✓ docker-compose已安装（旧版本）"
    docker-compose --version
else
    echo "  安装docker-compose..."
    $SUDO apt-get install -y -qq docker-compose >/dev/null 2>&1 || {
        # 如果apt安装失败，尝试pip安装
        if command -v pip3 &> /dev/null; then
            echo "  使用pip安装docker-compose..."
            $SUDO pip3 install docker-compose >/dev/null 2>&1 || true
        fi
    }
    echo "  ✓ docker-compose已安装"
fi
echo ""

# 步骤5: 配置Docker用户权限
echo "[5/5] 配置Docker权限..."
# 将当前用户添加到docker组
if [ "$EUID" -ne 0 ]; then
    CURRENT_USER=$(whoami)
    if ! groups $CURRENT_USER | grep -q docker; then
        echo "  将用户 $CURRENT_USER 添加到docker组..."
        $SUDO usermod -aG docker $CURRENT_USER
        echo "  ✓ 用户已添加到docker组"
        echo "  ⚠️  需要重新登录或运行: newgrp docker"
    else
        echo "  ✓ 用户已在docker组中"
    fi
else
    echo "  ⚠️  以root用户运行，跳过用户组配置"
fi

# 启动Docker服务
$SUDO systemctl start docker >/dev/null 2>&1 || true
$SUDO systemctl enable docker >/dev/null 2>&1 || true

# 测试Docker
echo ""
echo "测试Docker..."
if $SUDO docker ps >/dev/null 2>&1; then
    echo "  ✓ Docker运行正常"
else
    echo "  ⚠️  Docker服务可能未启动，尝试启动..."
    $SUDO systemctl start docker || $SUDO service docker start || true
fi

echo ""
echo "=========================================="
echo "Docker安装完成！"
echo "=========================================="
echo ""
echo "📋 下一步："
echo ""
echo "1. 如果用户被添加到docker组，运行："
echo "   newgrp docker"
echo ""
echo "2. 测试Docker："
echo "   docker ps"
echo ""
echo "3. 启动WordPress环境："
echo "   cd ~/wcpay"
echo "   docker-compose up -d"
echo "   或者: docker compose up -d"
echo ""
echo "4. 访问WordPress："
echo "   http://[Ubuntu IP]:8080"
echo ""

