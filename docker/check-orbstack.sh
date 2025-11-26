#!/bin/bash

# 检查是否在OrbStack环境中

echo "=========================================="
echo "检查运行环境"
echo "=========================================="
echo ""

# 检查方法1: 检查OrbStack特定目录
if [ -d "/run/orbstack" ]; then
    echo "✓ 检测到OrbStack目录: /run/orbstack"
fi

# 检查方法2: 检查OrbStack标志文件
if [ -f "/opt/orbstack" ]; then
    echo "✓ 检测到OrbStack文件: /opt/orbstack"
fi

# 检查方法3: 检查主机名
if grep -qi "orbstack" /etc/hostname 2>/dev/null || hostname | grep -qi "orbstack"; then
    echo "✓ 主机名包含OrbStack: $(hostname)"
fi

# 检查方法4: 检查虚拟化
if command -v systemd-detect-virt &> /dev/null; then
    VIRT=$(systemd-detect-virt 2>/dev/null)
    echo "虚拟化类型: $VIRT"
fi

# 检查方法5: 检查系统信息
echo ""
echo "系统信息："
echo "  操作系统: $(cat /etc/os-release | grep "^NAME=" | cut -d'"' -f2 || echo "未知")"
echo "  内核版本: $(uname -r)"
echo "  主机名: $(hostname)"
echo "  IP地址: $(hostname -I | awk '{print $1}' || echo "未知")"

# 检查方法6: 检查是否在容器中
if [ -f /.dockerenv ]; then
    echo ""
    echo "⚠️  当前在Docker容器中运行"
else
    echo ""
    echo "✓ 当前在系统环境中运行"
fi

# 检查Docker
echo ""
echo "Docker状态："
if command -v docker &> /dev/null; then
    echo "  ✓ Docker已安装: $(docker --version)"
    if docker ps >/dev/null 2>&1; then
        echo "  ✓ Docker服务运行中"
    else
        echo "  ⚠️  Docker服务未运行"
    fi
else
    echo "  ✗ Docker未安装"
fi

# 检查docker-compose
if docker compose version &> /dev/null 2>/dev/null || command -v docker-compose &> /dev/null; then
    echo "  ✓ docker-compose已安装"
else
    echo "  ✗ docker-compose未安装"
fi

echo ""
echo "=========================================="
echo "总结"
echo "=========================================="
echo ""
echo "如果你在OrbStack的Ubuntu实例中运行此脚本，"
echo "即使没有明确检测到OrbStack标志，也可以继续。"
echo ""
echo "Docker安装脚本适用于任何Ubuntu系统，"
echo "包括OrbStack、VMware、VirtualBox等。"
echo ""

